import Foundation

@MainActor
internal protocol StoreContextProtocol {
    func read<Node: Atom>(_ atom: Node, dependent: StoreContext?) -> Node.Loader.Value
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node, dependent: StoreContext?)
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction, dependent: StoreContext?) -> Node.Loader.Value
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        dependent: StoreContext?,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value
    func refresh<Node: Atom>(_ atom: Node, dependent: StoreContext?) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader
    func reset(_ atom: some Atom, dependent: StoreContext?)
    func snapshot() -> Snapshot
    func notifyUpdate(for keys: Set<AtomKey>, dependent: StoreContext?)
}

@usableFromInline
internal struct StoreContext: StoreContextProtocol {
    private weak var weakStore: AtomStore?
    private let parent: StoreContextProtocol?
    private let overrides: Overrides
    private let observers: [Observer]
    private let enablesAssertion: Bool

    nonisolated init(
        _ store: AtomStore? = nil,
        parent: StoreContextProtocol? = nil,
        overrides: Overrides = Overrides(),
        observers: [Observer] = [],
        enablesAssertion: Bool = false
    ) {
        self.weakStore = store
        self.parent = parent
        self.overrides = overrides
        self.observers = observers
        self.enablesAssertion = enablesAssertion
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node, dependent: StoreContext? = nil) -> Node.Loader.Value {
        let key = AtomKey(atom)

        func readCurrent(override: Node.Loader.Value?) -> Node.Loader.Value {
            let value = getNewValue(of: atom, for: key, override: override, dependent: dependent)
            notifyUpdateToObservers()
            checkRelease(for: key)
            return value
        }

        if let cache = peekCache(of: atom, for: key) {
            checkRelease(for: key)
            return cache.value
        }
        else if let override = overrides.value(for: atom) {
            return readCurrent(override: override)
        }
        else if let parent {
            return parent.read(atom, dependent: dependent)
        }
        else {
            return readCurrent(override: nil)
        }
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node, dependent: StoreContext? = nil) {
        let key = AtomKey(atom)

        if let cache = peekCache(of: atom, for: key) {
            update(atom: atom, for: key, value: value, cache: cache, dependent: dependent)
            checkRelease(for: key)
        }
        else if let parent {
            parent.set(value, for: atom, dependent: dependent)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction, dependent: StoreContext? = nil) -> Node.Loader.Value {
        guard !transaction.isTerminated else {
            return read(atom, dependent: dependent)
        }

        let key = AtomKey(atom)

        func watchCurrent(cache: AtomCache<Node>?, override: Node.Loader.Value? = nil) -> Node.Loader.Value {
            let store = getStore()
            // Add an `Edge` from the upstream to downstream.
            store.graph.dependencies[transaction.key, default: []].insert(key)

            let isInserted = store.graph.children[key, default: []].insert(transaction.key).inserted
            let value = cache?.value ?? getNewValue(of: atom, for: key, override: override, dependent: dependent)

            if isInserted || cache == nil {
                notifyUpdateToObservers()
            }

            return value
        }

        if let cache = peekCache(of: atom, for: key) {
            return watchCurrent(cache: cache, override: nil)
        }
        else if let override = overrides.value(for: atom) {
            return watchCurrent(cache: nil, override: override)
        }
        else if let parent {
            return parent.watch(atom, in: transaction, dependent: dependent)
        }
        else {
            return watchCurrent(cache: nil, override: nil)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        dependent: StoreContext? = nil,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        let key = AtomKey(atom)

        func watchCurrent(cache: AtomCache<Node>?, override: Node.Loader.Value?) -> Node.Loader.Value {
            let store = getStore()
            let subscription = Subscription(notifyUpdate: notifyUpdate) { [weak store] in
                guard let store else {
                    return
                }

                // Unsubscribe and release if it's no longer used.
                store.state.subscriptions[key]?.removeValue(forKey: container.key)
                checkRelease(for: key)
            }

            // Register the subscription to both the store and the container.
            container.subscriptions[key] = subscription

            let isInserted = store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: container.key) == nil
            let value = cache?.value ?? getNewValue(of: atom, for: key, override: override, dependent: dependent)

            if isInserted || cache == nil {
                notifyUpdateToObservers()
            }

            return value
        }

        if let cache = peekCache(of: atom, for: key) {
            return watchCurrent(cache: cache, override: nil)
        }
        else if let override = overrides.value(for: atom) {
            return watchCurrent(cache: nil, override: override)
        }
        else if let parent {
            return parent.watch(atom, container: container, dependent: dependent, notifyUpdate: notifyUpdate)
        }
        else {
            return watchCurrent(cache: nil, override: nil)
        }
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node, dependent: StoreContext? = nil) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let key = AtomKey(atom)

        func refreshCurrent(override: Node.Loader.Value?) async -> Node.Loader.Value {
            let context = prepareTransaction(of: atom, for: key, dependent: dependent)
            let value: Node.Loader.Value

            if let override {
                value = await atom._loader.refresh(context: context, with: override)
            }
            else {
                value = await atom._loader.refresh(context: context)
            }

            if let cache = peekCache(of: atom, for: key) {
                update(atom: atom, for: key, value: value, cache: cache, dependent: dependent)
            }

            checkRelease(for: key)
            return value
        }

        if let override = overrides.value(for: atom) {
            return await refreshCurrent(override: override)
        }
        else if let parent {
            return await parent.refresh(atom, dependent: dependent)
        }
        else {
            return await refreshCurrent(override: nil)
        }
    }

    @usableFromInline
    func reset<Node: Atom>(_ atom: Node, dependent: StoreContext? = nil) {
        let key = AtomKey(atom)

        func resetCurrent(override: Node.Loader.Value?) {
            let cache = peekCache(of: atom, for: key)
            let value = getNewValue(of: atom, for: key, override: override, dependent: dependent)

            if let cache {
                update(atom: atom, for: key, value: value, cache: cache, dependent: dependent)
            }

            checkRelease(for: key)
        }

        if let override = overrides.value(for: atom) {
            resetCurrent(override: override)
        }
        else if let parent {
            parent.reset(atom, dependent: dependent)
        }
        else {
            resetCurrent(override: nil)
        }
    }

    @usableFromInline
    func snapshot() -> Snapshot {
        let store = getStore()
        let graph = store.graph
        let caches = store.state.caches
        let subscriptions = store.state.subscriptions

        return Snapshot(
            graph: graph,
            caches: caches,
            subscriptions: subscriptions
        ) {
            let store = getStore()
            let keys = ContiguousArray(caches.keys)
            var obsoletedDependencies = [AtomKey: Set<AtomKey>]()

            for key in keys {
                let oldDependencies = store.graph.dependencies[key]
                let newDependencies = graph.dependencies[key]

                // Update atom values and the graph.
                store.state.caches[key] = caches[key]
                store.graph.dependencies[key] = newDependencies
                store.graph.children[key] = graph.children[key]
                obsoletedDependencies[key] = oldDependencies?.subtracting(newDependencies ?? [])
            }

            for key in keys {
                // Release if the atom is no longer used.
                checkRelease(for: key)

                // Release dependencies that are no longer dependent.
                if let dependencies = obsoletedDependencies[key] {
                    checkReleaseDependencies(dependencies, for: key)
                }

                // Notify updates only for the subscriptions of restored atoms.
                if let subscriptions = store.state.subscriptions[key] {
                    for subscription in ContiguousArray(subscriptions.values) {
                        subscription.notifyUpdate()
                    }
                }
            }
        }
    }

    func notifyUpdate(for keys: Set<AtomKey>, dependent: StoreContext?) {
        parent?.notifyUpdate(for: keys, dependent: dependent)

        let store = getStore()

        // Reset the atom value and then notify update to downstream atoms.
        for key in keys {
            guard let cache = store.state.caches[key] else {
                continue
            }

            reset(cache.atom, dependent: dependent)
        }
    }

    func scoped(
        store: AtomStore,
        overrides: Overrides,
        observers: [Observer]
    ) -> Self {
        Self(
            store,
            parent: StoreContext(
                weakStore,
                parent: parent,
                overrides: self.overrides,
                observers: self.observers + observers,
                enablesAssertion: enablesAssertion
            ),
            overrides: overrides,
            observers: self.observers + observers
        )
    }
}

private extension StoreContext {
    func prepareTransaction<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        dependent: StoreContext?
    ) -> AtomLoaderContext<Node.Loader.Value, Node.Loader.Coordinator> {
        let state = getState(of: atom, for: key)

        // Invalidate dependencies and an ongoing transaction.
        let oldDependencies = invalidate(for: key)
        let transaction = Transaction(key: key) {
            let store = getStore()
            let dependencies = store.graph.dependencies[key] ?? []
            let obsoletedDependencies = oldDependencies.subtracting(dependencies)

            // Check if the dependencies that are no longer used and release them if possible.
            checkReleaseDependencies(obsoletedDependencies, for: key)
        }

        // Register the transaction state so it can be terminated from anywhere.
        state.transaction = transaction

        return AtomLoaderContext(
            store: dependent ?? self,
            transaction: transaction,
            coordinator: state.coordinator
        ) { value, needsEnsureValueUpdate in
            guard let cache = peekCache(of: atom, for: key) else {
                return
            }

            update(
                atom: atom,
                for: key,
                value: value,
                cache: cache,
                needsEnsureValueUpdate: needsEnsureValueUpdate,
                dependent: dependent
            )
        }
    }

    func getNewValue<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: Node.Loader.Value?,
        dependent: StoreContext?
    ) -> Node.Loader.Value {
        let store = getStore()
        let context = prepareTransaction(of: atom, for: key, dependent: dependent)
        let value: Node.Loader.Value

        if let override {
            value = atom._loader.handle(context: context, with: override)
        }
        else {
            value = atom._loader.get(context: context)
        }

        let cache = AtomCache(atom: atom, value: value)
        store.state.caches[key] = cache

        return value
    }

    func peekCache<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomCache<Node>? {
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
            return nil
        }

        return cache
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
            return makeState()
        }

        return state
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        value: Node.Loader.Value,
        cache: AtomCache<Node>,
        needsEnsureValueUpdate: Bool = false,
        dependent: StoreContext?
    ) {
        let store = getStore()
        let oldValue = cache.value
        var cache = cache

        // Update the current value with the new value.
        cache.value = value
        store.state.caches[key] = cache

        // Do not notify update if the new value and the old value are equivalent.
        if !atom._loader.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, needsEnsureValueUpdate: needsEnsureValueUpdate, dependent: dependent)

        // Notify value update to observers.
        notifyUpdateToObservers()

        func notifyUpdated() {
            let context = AtomUpdatedContext(store: dependent ?? self)
            atom.updated(newValue: value, oldValue: oldValue, context: context)
        }

        // Ensures the value is updated.
        if needsEnsureValueUpdate {
            RunLoop.current.perform {
                notifyUpdated()
            }
        }
        else {
            notifyUpdated()
        }
    }

    func notifyUpdate(for key: AtomKey, needsEnsureValueUpdate: Bool, dependent: StoreContext?) {
        let store = getStore()

        // Notifying update to view subscriptions first.
        if let subscriptions = store.state.subscriptions[key], !subscriptions.isEmpty {
            for subscription in ContiguousArray(subscriptions.values) {
                subscription.notifyUpdate()
            }
        }

        if let children = store.graph.children[key], !children.isEmpty {
            // At the timing when `ObservableObject/objectWillChange` emits, its properties
            // have not yet been updated and are still old when dependent atoms read it.
            // As a workaround, the update is executed in the next run loop
            // so that the downstream atoms can receive the object that's already updated.
            if needsEnsureValueUpdate {
                RunLoop.current.perform {
                    notifyUpdate(for: children, dependent: dependent)
                }
            }
            else {
                notifyUpdate(for: children, dependent: dependent)
            }
        }
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

    func release(for key: AtomKey) {
        let store = getStore()

        // Invalidate transactions, dependencies, and the atom state.
        let dependencies = invalidate(for: key)
        store.graph.children.removeValue(forKey: key)
        store.state.caches.removeValue(forKey: key)
        store.state.states.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)

        // Check if the dependencies are releasable.
        checkReleaseDependencies(dependencies, for: key)

        // Notify release.
        notifyUpdateToObservers()
    }

    func checkRelease(for key: AtomKey) {
        let store = getStore()

        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        let shouldKeepAlive = store.state.caches[key]?.shouldKeepAlive ?? false
        let shouldRelease =
            !shouldKeepAlive
            && (store.graph.children[key]?.isEmpty ?? true)
            && (store.state.subscriptions[key]?.isEmpty ?? true)

        guard shouldRelease else {
            return
        }

        release(for: key)
    }

    func checkReleaseDependencies(_ dependencies: Set<AtomKey>, for key: AtomKey) {
        let store = getStore()

        // Recursively release dependencies while unlinking the dependent.
        for dependency in dependencies {
            store.graph.children[dependency]?.remove(key)
            checkRelease(for: dependency)
        }
    }

    func invalidate(for key: AtomKey) -> Set<AtomKey> {
        let store = getStore()

        // Remove the current transaction and then terminate to prevent it to watch new atoms
        // or add new terminations.
        // Then, temporarily remove dependencies but do not release them recursively here.
        store.state.states[key]?.transaction?.terminate()
        return store.graph.dependencies.removeValue(forKey: key) ?? []
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
