import Foundation

@usableFromInline
@MainActor
internal struct StoreContext {
    private(set) weak var weakStore: AtomStore?
    private let overrides: [OverrideKey: any AtomScopedOverrideProtocol]
    private let observers: [Observer]
    private let enablesAssertion: Bool

    nonisolated init(
        _ store: AtomStore? = nil,
        observers: [Observer] = [],
        overrides: [OverrideKey: any AtomScopedOverrideProtocol] = [:],
        enablesAssertion: Bool = false
    ) {
        self.weakStore = store
        self.observers = observers
        self.overrides = overrides
        self.enablesAssertion = enablesAssertion
    }

    static func scoped(
        key: ScopeKey,
        store: AtomStore,
        observers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol]
    ) -> Self {
        StoreContext(
            store,
            observers: observers,
            overrides: overrides.mapValues { $0.scoped(key: key) },
            enablesAssertion: false
        )
    }

    func scoped(
        key: ScopeKey,
        observers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol]
    ) -> Self {
        StoreContext(
            weakStore,
            observers: self.observers + observers,
            overrides: self.overrides.merging(
                overrides.lazy.map { ($0, $1.scoped(key: key)) },
                uniquingKeysWith: { $1 }
            ),
            enablesAssertion: enablesAssertion
        )
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            return cache.value
        }
        else {
            let cache = makeNewCache(of: atom, for: key, override: override)
            notifyUpdateToObservers()

            if checkRelease(for: key) {
                notifyUpdateToObservers()
            }

            return cache.value
        }
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            update(atom: atom, for: key, value: value, cache: cache, order: .newValue)
        }
    }

    @usableFromInline
    func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Loader.Value) -> Void) {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)

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
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)
        let newCache = lookupCache(of: atom, for: key) ?? makeNewCache(of: atom, for: key, override: override)

        // Add an `Edge` from the upstream to downstream.
        store.graph.dependencies[transaction.key, default: []].insert(key)
        store.graph.children[key, default: []].insert(transaction.key)

        return newCache.value
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        requiresObjectUpdate: Bool,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        let store = getStore()
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)
        let newCache = lookupCache(of: atom, for: key) ?? makeNewCache(of: atom, for: key, override: override)
        let subscription = Subscription(
            location: container.location,
            requiresObjectUpdate: requiresObjectUpdate,
            notifyUpdate: notifyUpdate
        )
        let isNewSubscription = container.subscribingKeys.insert(key).inserted

        store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: container.key)
        container.unsubscribe = { keys in
            unsubscribe(keys, for: container.key)
        }

        if isNewSubscription {
            notifyUpdateToObservers()
        }

        return newCache.value
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)
        let context = prepareTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = await atom._loader.refreshOverridden(value: override.value(atom), context: context)
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
    func reset(_ atom: some Atom) {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            let newCache = makeNewCache(of: atom, for: key, override: override)
            update(atom: atom, for: key, value: newCache.value, cache: cache, order: .newValue)
        }
    }

    @usableFromInline
    func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)
        let cache = lookupCache(of: atom, for: key)

        return cache?.value
    }

    @usableFromInline
    func unwatch(_ atom: some Atom, container: SubscriptionContainer.Wrapper) {
        let override = lookupOverride(of: atom)
        let key = AtomKey(atom, overrideScopeKey: override?.scopeKey)

        container.subscribingKeys.remove(key)
        unsubscribe([key], for: container.key)
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
            checkRelease(for: key)

            // Release dependencies that are no longer dependent.
            if let dependencies = obsoletedDependencies[key] {
                for dependency in ContiguousArray(dependencies) {
                    store.graph.children[dependency]?.remove(key)
                    checkRelease(for: dependency)
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
    func makeNewCache<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: AtomScopedOverride<Node>?
    ) -> AtomCache<Node> {
        let store = getStore()
        let context = prepareTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = atom._loader.associateOverridden(value: override.value(atom), context: context)
        }
        else {
            value = atom._loader.value(context: context)
        }

        let cache = AtomCache(atom: atom, value: value)
        store.state.caches[key] = cache

        return cache
    }

    func prepareTransaction<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomLoaderContext<Node.Loader.Value, Node.Loader.Coordinator> {
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
                checkRelease(for: dependency)
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
                    // Reset the atom value and then notify update to downstream atoms.
                    if let cache = store.state.caches[child] {
                        reset(cache.atom)
                    }
                }
            }

            // Notify value update to observers.
            notifyUpdateToObservers()

            let state = getState(of: atom, for: key)
            let context = AtomUpdatedContext(store: self, coordinator: state.coordinator)
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

    func unsubscribe<Keys: Sequence<AtomKey>>(_ keys: Keys, for subscriptionKey: SubscriptionKey) {
        let store = getStore()

        for key in ContiguousArray(keys) {
            store.state.subscriptions[key]?.removeValue(forKey: subscriptionKey)
            checkRelease(for: key)
        }

        notifyUpdateToObservers()
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
                checkRelease(for: dependency)
            }
        }
    }

    @discardableResult
    func checkRelease(for key: AtomKey) -> Bool {
        let store = getStore()

        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive` or is overridden.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        lazy var shouldKeepAlive = !key.isOverridden && store.state.caches[key].map { $0.atom is any KeepAlive } ?? false
        lazy var isChildrenEmpty = store.graph.children[key]?.isEmpty ?? true
        lazy var isSubscriptionEmpty = store.state.subscriptions[key]?.isEmpty ?? true
        lazy var shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

        guard shouldRelease else {
            return false
        }

        release(for: key)
        return true
    }

    func notifyUpdateToObservers() {
        guard !observers.isEmpty else {
            return
        }

        let snapshot = snapshot()

        for observer in observers {
            observer.onUpdate(snapshot)
        }
    }

    func lookupOverride<Node: Atom>(of atom: Node) -> AtomScopedOverride<Node>? {
        let baseOverride = overrides[OverrideKey(atom)] ?? overrides[OverrideKey(Node.self)]

        guard let baseOverride else {
            return nil
        }

        guard let override = baseOverride as? AtomScopedOverride<Node> else {
            assertionFailure(
                """
                [Atoms]
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: baseOverride))
                Expected: AtomScopedOverride<\(Node.self)>
                """
            )

            return nil
        }

        return override
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
                        AtomScope(context) {
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
                AtomScope(context) {
                    ExampleView()
                }
            }
            ```
            """
        )

        return AtomStore()
    }
}
