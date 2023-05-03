import Foundation

@usableFromInline
@MainActor
internal struct StoreContext {
    private weak var weakStore: AtomStore?
    private let overrides: Overrides?
    private let observers: [Observer]
    private let enablesAssertion: Bool

    nonisolated init(
        _ store: AtomStore? = nil,
        overrides: Overrides? = nil,
        observers: [Observer] = [],
        enablesAssertion: Bool = false
    ) {
        self.weakStore = store
        self.overrides = overrides
        self.observers = observers
        self.enablesAssertion = enablesAssertion
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        let key = AtomKey(atom)
        defer { checkRelease(for: key) }

        let (isNew, value) = getValue(of: atom, for: key)

        if isNew {
            notifyUpdateToObservers()
        }

        return value
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        let key = AtomKey(atom)
        update(atom: atom, for: key, with: value)
        checkRelease(for: key)
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        // Return a new value immediately if the transaction is already terminated.
        guard !transaction.isTerminated else {
            return read(atom)
        }

        let store = getStore()
        let key = AtomKey(atom)

        // Add an `Edge` from the upstream to downstream.
        store.graph.dependencies[transaction.key, default: []].insert(key)

        let isInserted = store.graph.children[key, default: []].insert(transaction.key).inserted
        let (isNew, value) = getValue(of: atom, for: key)

        if isInserted || isNew {
            notifyUpdateToObservers()
        }

        return value
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        let store = getStore()
        let key = AtomKey(atom)
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
        let (isNew, value) = getValue(of: atom, for: key)

        if isInserted || isNew {
            notifyUpdateToObservers()
        }

        return value
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let key = AtomKey(atom)
        let context = prepareTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let overrideValue = overrides?.value(for: atom) {
            value = await atom._loader.refresh(context: context, with: overrideValue)
        }
        else {
            value = await atom._loader.refresh(context: context)
        }

        // Update the current value with the fresh value.
        update(atom: atom, for: key, with: value)
        checkRelease(for: key)

        return value
    }

    @usableFromInline
    func reset(_ atom: some Atom) {
        let key = AtomKey(atom)
        let value = getNewValue(of: atom, for: key)

        update(atom: atom, for: key, with: value)
        checkRelease(for: key)
    }

    @usableFromInline
    func snapshot() -> Snapshot {
        let store = getStore()
        let graph = store.graph
        let caches = store.state.caches
        let subscriptions = store.state.subscriptions

        return Snapshot(graph: graph, caches: caches, subscriptions: subscriptions) {
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

    @usableFromInline
    func scoped(observers: [Observer]) -> Self {
        Self(
            weakStore,
            overrides: overrides,
            observers: self.observers + observers
        )
    }
}

private extension StoreContext {
    func prepareTransaction<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomLoaderContext<Node.Loader.Value, Node.Loader.Coordinator> {
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
            store: self,
            transaction: transaction,
            coordinator: state.coordinator
        ) { value, needsEnsureValueUpdate in
            update(
                atom: atom,
                for: key,
                with: value,
                needsEnsureValueUpdate: needsEnsureValueUpdate
            )
        }
    }

    func getNewValue<Node: Atom>(of atom: Node, for key: AtomKey) -> Node.Loader.Value {
        let context = prepareTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let overrideValue = overrides?.value(for: atom) {
            value = atom._loader.handle(context: context, with: overrideValue)
        }
        else {
            value = atom._loader.get(context: context)
        }

        return value
    }

    func getValue<Node: Atom>(of atom: Node, for key: AtomKey) -> (isNew: Bool, value: Node.Loader.Value) {
        let store = getStore()
        var cache = getCache(of: atom, for: key)

        if let value = cache.value {
            return (isNew: false, value: value)
        }
        else {
            let value = getNewValue(of: atom, for: key)

            cache.value = value
            store.state.caches[key] = cache

            return (isNew: true, value: value)
        }
    }

    func getCache<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomCache<Node> {
        let store = getStore()

        if let cache = peekCache(of: atom, for: key) {
            return cache
        }
        else {
            let cache = AtomCache(atom: atom)
            store.state.caches[key] = cache

            return cache
        }
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

    func notifyUpdate(for key: AtomKey, needsEnsureValueUpdate: Bool = false) {
        let store = getStore()

        // Notifying update to view subscriptions first.
        if let subscriptions = store.state.subscriptions[key] {
            for subscription in ContiguousArray(subscriptions.values) {
                subscription.notifyUpdate()
            }
        }

        // Reset the atom value and then notify update to downstream atoms.
        func updateChildren() {
            guard let children = store.graph.children[key] else {
                return
            }

            for child in children {
                let cache = store.state.caches[child]
                cache?.reset(with: self)
            }
        }

        // At the timing when `ObservableObject/objectWillChange` emits, its properties
        // have not yet been updated and are still old when dependent atoms read it.
        // As a workaround, the update is executed in the next run loop
        // so that the downstream atoms can receive the object that's already updated.
        if needsEnsureValueUpdate {
            RunLoop.current.perform {
                updateChildren()
            }
        }
        else {
            updateChildren()
        }
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        with value: Node.Loader.Value,
        needsEnsureValueUpdate: Bool = false
    ) {
        let store = getStore()
        var cache = getCache(of: atom, for: key)
        let oldValue = cache.value

        // Update the current value with the new value.
        cache.value = value
        store.state.caches[key] = cache

        // Do not notify update if the new value and the old value are equivalent.
        if let oldValue, !atom._loader.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, needsEnsureValueUpdate: needsEnsureValueUpdate)

        // Notify value update.
        notifyUpdateToObservers()

        guard let oldValue else {
            return
        }

        func notifyUpdated() {
            let context = AtomUpdatedContext(store: self)
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
        let shouldKeepAlive = store.state.caches[key].map { $0 is any KeepAlive } ?? false
        let isChildrenEmpty = store.graph.children[key]?.isEmpty ?? true
        let isSubscriptionEmpty = store.state.subscriptions[key]?.isEmpty ?? true
        let shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

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

    func notifyUpdateToObservers() {
        guard !observers.isEmpty else {
            return
        }

        let snapshot = snapshot()

        for observer in observers {
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
