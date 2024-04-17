import Foundation

@usableFromInline
@MainActor
internal struct StoreContext {
    private weak var weakStore: AtomStore?
    private let scopeKey: ScopeKey
    private let inheritedScopeKeys: [ScopeID: ScopeKey]
    private let observers: [Observer]
    private let scopedObservers: [Observer]
    private let overrides: [OverrideKey: any AtomOverrideProtocol]
    private let enablesAssertion: Bool

    nonisolated init(
        _ store: AtomStore?,
        scopeKey: ScopeKey,
        inheritedScopeKeys: [ScopeID: ScopeKey],
        observers: [Observer],
        scopedObservers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol],
        enablesAssertion: Bool = false
    ) {
        self.weakStore = store
        self.scopeKey = scopeKey
        self.inheritedScopeKeys = inheritedScopeKeys
        self.observers = observers
        self.scopedObservers = scopedObservers
        self.overrides = overrides
        self.enablesAssertion = enablesAssertion
    }

    func inherited(
        scopedObservers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol]
    ) -> StoreContext {
        StoreContext(
            weakStore,
            scopeKey: scopeKey,
            inheritedScopeKeys: inheritedScopeKeys,
            observers: observers,
            scopedObservers: self.scopedObservers + scopedObservers,
            overrides: self.overrides.merging(overrides) { $1 },
            enablesAssertion: enablesAssertion
        )
    }

    func scoped(
        scopeKey: ScopeKey,
        scopeID: ScopeID,
        observers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol]
    ) -> StoreContext {
        StoreContext(
            weakStore,
            scopeKey: scopeKey,
            inheritedScopeKeys: mutating(inheritedScopeKeys) { $0[scopeID] = scopeKey },
            observers: self.observers,
            scopedObservers: observers,
            overrides: overrides,
            enablesAssertion: enablesAssertion
        )
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            return cache.value
        }
        else {
            let cache = makeNewCache(of: atom, for: key, override: override)
            notifyUpdateToObservers()

            if checkAndRelease(for: key) {
                notifyUpdateToObservers()
            }

            return cache.value
        }
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            update(atom: atom, for: key, value: value, cache: cache, order: .newValue)
        }
    }

    @usableFromInline
    func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Loader.Value) -> Void) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            var value = cache.value
            body(&value)
            update(atom: atom, for: key, value: value, cache: cache, order: .newValue)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        guard !transaction.isTerminated else {
            return read(atom)
        }

        let store = getStore()
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let newCache = lookupCache(of: atom, for: key) ?? makeNewCache(of: atom, for: key, override: override)

        // Add an `Edge` from the upstream to downstream.
        store.graph.dependencies[transaction.key, default: []].insert(key)
        store.graph.children[key, default: []].insert(transaction.key)

        return newCache.value
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        subscriber: Subscriber,
        requiresObjectUpdate: Bool,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        let store = getStore()
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let newCache = lookupCache(of: atom, for: key) ?? makeNewCache(of: atom, for: key, override: override)
        let subscription = Subscription(
            location: subscriber.location,
            requiresObjectUpdate: requiresObjectUpdate,
            notifyUpdate: notifyUpdate
        )
        let isNewSubscription = subscriber.subscribingKeys.insert(key).inserted

        store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: subscriber.key)
        subscriber.unsubscribe = { keys in
            unsubscribe(keys, for: subscriber.key)
        }

        if isNewSubscription {
            notifyUpdateToObservers()
        }

        return newCache.value
    }

    @usableFromInline
    @_disfavoredOverload
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let context = prepareForTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = await atom._loader.refresh(overridden: override.value(atom), context: context)
        }
        else {
            value = await atom._loader.refresh(context: context)
        }

        guard let cache = lookupCache(of: atom, for: key) else {
            // Release the temporarily created state.
            // Do not notify update to observers here because refresh doesn't create a new cache.
            release(for: key)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !context.transaction.isTerminated {
            update(atom: atom, for: key, value: value, cache: cache, order: .newValue)
        }

        return value
    }

    @usableFromInline
    func refresh<Node: Refreshable>(_ atom: Node) async -> Node.Loader.Value {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let state = getState(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = override.value(atom)
        }
        else {
            let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
            value = await atom.refresh(context: context)
        }

        guard let transaction = state.transaction, let cache = lookupCache(of: atom, for: key) else {
            // Release the temporarily created state.
            // Do not notify update to observers here because refresh doesn't create a new cache.
            release(for: key)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !transaction.isTerminated {
            update(atom: atom, for: key, value: value, cache: cache, order: .newValue)
        }

        return value
    }

    @usableFromInline
    @_disfavoredOverload
    func reset<Node: Atom>(_ atom: Node) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            let newCache = makeNewCache(of: atom, for: key, override: override)
            update(atom: atom, for: key, value: newCache.value, cache: cache, order: .newValue)
        }
    }

    @usableFromInline
    func reset<Node: Resettable>(_ atom: Node) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)

        guard let override else {
            let state = getState(of: atom, for: key)
            let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
            return atom.reset(context: context)
        }

        if let cache = lookupCache(of: atom, for: key) {
            let newCache = makeNewCache(of: atom, for: key, override: override)
            update(atom: atom, for: key, value: newCache.value, cache: cache, order: .newValue)
        }
    }

    @usableFromInline
    func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let cache = lookupCache(of: atom, for: key)

        return cache?.value
    }

    @usableFromInline
    func unwatch(_ atom: some Atom, subscriber: Subscriber) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isOverridden: override != nil)
        let key = AtomKey(atom, scopeKey: scopeKey)

        subscriber.subscribingKeys.remove(key)
        unsubscribe([key], for: subscriber.key)
    }

    @usableFromInline
    func snapshot() -> Snapshot {
        let store = getStore()

        return Snapshot(
            graph: store.graph,
            caches: store.state.caches,
            subscriptions: store.state.subscriptions
        )
    }

    @usableFromInline
    func restore(_ snapshot: Snapshot) {
        let store = getStore()
        let keys = ContiguousArray(snapshot.caches.keys)
        var obsoletedDependencies = [AtomKey: Set<AtomKey>]()

        for key in keys {
            let oldDependencies = store.graph.dependencies[key]
            let newDependencies = snapshot.graph.dependencies[key]

            // Update atom values and the graph.
            store.state.caches[key] = snapshot.caches[key]
            store.graph.dependencies[key] = newDependencies
            store.graph.children[key] = snapshot.graph.children[key]
            obsoletedDependencies[key] = oldDependencies?.subtracting(newDependencies ?? [])
        }

        for key in keys {
            // Release if the atom is no longer used.
            checkAndRelease(for: key)

            // Release dependencies that are no longer dependent.
            if let dependencies = obsoletedDependencies[key] {
                for dependency in ContiguousArray(dependencies) {
                    store.graph.children[dependency]?.remove(key)
                    checkAndRelease(for: dependency)
                }
            }

            // Notify updates only for the subscriptions of restored atoms.
            if let subscriptions = store.state.subscriptions[key] {
                for subscription in ContiguousArray(subscriptions.values) {
                    subscription.notifyUpdate()
                }
            }
        }

        notifyUpdateToObservers()
    }
}

private extension StoreContext {
    func prepareForTransaction<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomLoaderContext<Node.Loader.Value, Node.Loader.Coordinator> {
        let store = getStore()
        let state = getState(of: atom, for: key)

        // Terminate the ongoing transaction first.
        state.transaction?.terminate()

        // Remove current dependencies.
        let oldDependencies = store.graph.dependencies.removeValue(forKey: key) ?? []

        // Detatch the atom from its dependencies.
        for dependency in ContiguousArray(oldDependencies) {
            store.graph.children[dependency]?.remove(key)
        }

        let transaction = Transaction(key: key) {
            let store = getStore()
            let dependencies = store.graph.dependencies[key] ?? []
            let obsoletedDependencies = oldDependencies.subtracting(dependencies)
            let newDependencies = dependencies.subtracting(oldDependencies)

            for dependency in ContiguousArray(obsoletedDependencies) {
                checkAndRelease(for: dependency)
            }

            if !obsoletedDependencies.isEmpty || !newDependencies.isEmpty {
                notifyUpdateToObservers()
            }
        }

        // Register the transaction state so it can be terminated from anywhere.
        state.transaction = transaction

        return AtomLoaderContext(
            store: self,
            transaction: transaction,
            coordinator: state.coordinator
        ) { value, order in
            guard let cache = lookupCache(of: atom, for: key) else {
                return
            }

            update(
                atom: atom,
                for: key,
                value: value,
                cache: cache,
                order: order
            )
        }
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        value: Node.Loader.Value,
        cache: AtomCache<Node>,
        order: UpdateOrder
    ) {
        let store = getStore()
        let oldValue = cache.value

        if case .newValue = order {
            var cache = cache
            cache.value = value
            store.state.caches[key] = cache
        }

        // Do not notify update if the new value and the old value are equivalent.
        if !atom._loader.shouldUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        // Notifying update to view subscriptions first.
        if let subscriptions = store.state.subscriptions[key] {
            for subscription in ContiguousArray(subscriptions.values) {
                if case .objectWillChange = order, subscription.requiresObjectUpdate {
                    RunLoop.current.perform(subscription.notifyUpdate)
                }
                else {
                    subscription.notifyUpdate()
                }
            }
        }

        func notifyUpdate() {
            if let children = store.graph.children[key] {
                for child in ContiguousArray(children) {
                    // Reset the atom value and then notifies downstream atoms.
                    if let cache = store.state.caches[child] {
                        reset(cache.atom)
                    }
                }
            }

            // Notify value update to observers.
            notifyUpdateToObservers()

            let state = getState(of: atom, for: key)
            let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
            atom.updated(newValue: value, oldValue: oldValue, context: context)
        }

        switch order {
        case .newValue:
            notifyUpdate()

        case .objectWillChange:
            // At the timing when `ObservableObject/objectWillChange` emits, its properties
            // have not yet been updated and are still old when dependent atoms read it.
            // As a workaround, the update is executed in the next run loop
            // so that the downstream atoms can receive the object that's already updated.
            RunLoop.current.perform {
                notifyUpdate()
            }
        }
    }

    func unsubscribe<Keys: Sequence<AtomKey>>(_ keys: Keys, for subscriberKey: SubscriberKey) {
        let store = getStore()

        for key in ContiguousArray(keys) {
            store.state.subscriptions[key]?.removeValue(forKey: subscriberKey)
            checkAndRelease(for: key)
        }

        notifyUpdateToObservers()
    }

    @discardableResult
    func checkAndRelease(for key: AtomKey) -> Bool {
        let store = getStore()

        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`, is marked as `Scoped`, or is scoped by override.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        lazy var shouldKeepAlive = !key.isScoped && store.state.caches[key].map { $0.atom is any KeepAlive } ?? false
        lazy var isChildrenEmpty = store.graph.children[key]?.isEmpty ?? true
        lazy var isSubscriptionEmpty = store.state.subscriptions[key]?.isEmpty ?? true
        lazy var shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

        guard shouldRelease else {
            return false
        }

        release(for: key)
        return true
    }

    func release(for key: AtomKey) {
        // Invalidate transactions, dependencies, and the atom state.
        let store = getStore()
        let dependencies = store.graph.dependencies.removeValue(forKey: key)
        let state = store.state.states.removeValue(forKey: key)
        store.graph.children.removeValue(forKey: key)
        store.state.caches.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)
        state?.transaction?.terminate()

        if let dependencies {
            for dependency in ContiguousArray(dependencies) {
                store.graph.children[dependency]?.remove(key)
                checkAndRelease(for: dependency)
            }
        }
    }

    func getState<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomState<Node.Coordinator> {
        let store = getStore()

        func makeState() -> AtomState<Node.Coordinator> {
            let coordinator = atom.makeCoordinator()
            let state = AtomState(coordinator: coordinator)
            store.state.states[key] = state
            return state
        }

        guard let baseState = store.state.states[key] else {
            return makeState()
        }

        guard let state = baseState as? AtomState<Node.Coordinator> else {
            assertionFailure(
                """
                [Atoms]
                The type of the given atom's value and the state did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom: \(Node.self)
                Key: \(type(of: atom.key))
                Detected: \(type(of: baseState))
                Expected: AtomState<\(Node.Coordinator.self)>
                """
            )

            // Release the invalid registration as a fallback.
            release(for: key)
            notifyUpdateToObservers()
            return makeState()
        }

        return state
    }

    func makeNewCache<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: AtomOverride<Node>?
    ) -> AtomCache<Node> {
        let store = getStore()
        let context = prepareForTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = atom._loader.manageOverridden(value: override.value(atom), context: context)
        }
        else {
            value = atom._loader.value(context: context)
        }

        let cache = AtomCache(atom: atom, value: value)
        store.state.caches[key] = cache

        return cache
    }

    func lookupCache<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomCache<Node>? {
        let store = getStore()

        guard let baseCache = store.state.caches[key] else {
            return nil
        }

        guard let cache = baseCache as? AtomCache<Node> else {
            assertionFailure(
                """
                [Atoms]
                The type of the given atom's value and the cache did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom: \(Node.self)
                Key: \(type(of: atom.key))
                Detected: \(type(of: baseCache))
                Expected: AtomCache<\(Node.self)>
                """
            )

            // Release the invalid registration as a fallback.
            release(for: key)
            notifyUpdateToObservers()
            return nil
        }

        return cache
    }

    func lookupOverride<Node: Atom>(of atom: Node) -> AtomOverride<Node>? {
        let baseOverride = overrides[OverrideKey(atom)] ?? overrides[OverrideKey(Node.self)]

        guard let baseOverride else {
            return nil
        }

        guard let override = baseOverride as? AtomOverride<Node> else {
            assertionFailure(
                """
                [Atoms]
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: baseOverride))
                Expected: AtomOverride<\(Node.self)>
                """
            )

            return nil
        }

        return override
    }

    func lookupScopeKey<Node: Atom>(of atom: Node, isOverridden: Bool) -> ScopeKey? {
        if isOverridden {
            return scopeKey
        }
        else if let atom = atom as? any Scoped {
            let scopeID = ScopeID(atom.scopeID)
            return inheritedScopeKeys[scopeID]
        }
        else {
            return nil
        }
    }

    func notifyUpdateToObservers() {
        guard !observers.isEmpty || !scopedObservers.isEmpty else {
            return
        }

        let snapshot = snapshot()

        for observer in observers + scopedObservers {
            observer.onUpdate(snapshot)
        }
    }

    func getStore() -> AtomStore {
        if let store = weakStore {
            return store
        }

        assert(
            !enablesAssertion,
            """
            [Atoms]
            There is no store provided on the current view tree.
            Make sure that this application has an `AtomRoot` as a root ancestor of any view.

            ```
            struct ExampleApp: App {
                var body: some Scene {
                    WindowGroup {
                        AtomRoot {
                            ExampleView()
                        }
                    }
                }
            }
            ```

            If for some reason the view tree is formed that does not inherit from `EnvironmentValues`,
            consider using `AtomScope` to pass it.
            That happens when using SwiftUI view wrapped with `UIHostingController`.

            ```
            struct ExampleView: View {
                @ViewContext
                var context

                var body: some View {
                    UIViewWrappingView {
                        AtomScope(inheriting: context) {
                            WrappedView()
                        }
                    }
                }
            }
            ```

            The modal screen presented by the `.sheet` modifier or etc, inherits from the environment values,
            but only in iOS14, there is a bug where the environment values will be dismantled during it is
            dismissing. This also can be avoided by using `AtomScope` to explicitly inherit from it.

            ```
            .sheet(isPresented: ...) {
                AtomScope(inheriting: context) {
                    ExampleView()
                }
            }
            ```
            """
        )

        return AtomStore()
    }
}
