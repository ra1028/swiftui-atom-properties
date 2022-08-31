import Foundation

@usableFromInline
@MainActor
internal struct StoreContext {
    private weak var weakStore: Store?
    private let overrides: Overrides?
    private let observers: [AtomObserver]

    nonisolated init(
        _ store: Store? = nil,
        overrides: Overrides? = nil,
        observers: [AtomObserver] = []
    ) {
        self.weakStore = store
        self.overrides = overrides
        self.observers = observers
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        let key = AtomKey(atom)
        defer { checkRelease(for: key) }

        return getValue(of: atom, for: key)
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        let key = AtomKey(atom)
        let cache = peekCache(of: atom, for: key)

        // Do nothing if the atom is not yet to be registered.
        guard let oldValue = cache?.value else {
            return
        }

        // Note that this is special handling for `willSet/didSet` because the dependencies could be invalidated
        // by `prepareTransaction` here and there's no timing to restore them.
        // The dependencies added by `willSet/didSet` will not be released until the value is invalidated and
        // is going to be a bug, so `AtomTransactionContenxt` will no longer be passed soon.
        // https://github.com/ra1028/swiftui-atom-properties/issues/18
        let state = getState(of: atom, for: key)
        let transaction = Transaction(key: key) {
            // Do nothing.
        }
        let context = AtomLoaderContext(
            store: self,
            transaction: transaction,
            coordinator: state.coordinator
        ) { value, updatesChildrenOnNextRunLoop in
            update(
                atom: atom,
                for: key,
                with: value,
                updatesChildrenOnNextRunLoop: updatesChildrenOnNextRunLoop
            )
        }

        context.transaction { context in
            atom.willSet(newValue: value, oldValue: oldValue, context: context)
            update(atom: atom, for: key, with: value)
            atom.didSet(newValue: value, oldValue: oldValue, context: context)
        }
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
        store.graph.children[key, default: []].insert(transaction.key)

        return getValue(of: atom, for: key)
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
            guard let store = store else {
                return
            }

            // Unsubscribe and release if it's no longer used.
            store.state.atomStates[key]?.subscriptions.removeValue(forKey: container.key)
            checkRelease(for: key)
        }

        // Register the subscription to both the store and the container.
        let state = getState(of: atom, for: key)
        state.subscriptions[container.key] = subscription
        container.subscriptions[key] = subscription

        return getValue(of: atom, for: key)
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
    func reset<Node: Atom>(_ atom: Node) {
        let key = AtomKey(atom)
        let value = getNewValue(of: atom, for: key)

        update(atom: atom, for: key, with: value)
        checkRelease(for: key)
    }

    @usableFromInline
    func relay(observers: [AtomObserver]) -> Self {
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
        ) { value, updatesChildrenOnNextRunLoop in
            update(
                atom: atom,
                for: key,
                with: value,
                updatesChildrenOnNextRunLoop: updatesChildrenOnNextRunLoop
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

    func getValue<Node: Atom>(of atom: Node, for key: AtomKey) -> Node.Loader.Value {
        let store = getStore()
        var cache = getCache(of: atom, for: key)

        if let value = cache.value {
            return value
        }
        else {
            let value = getNewValue(of: atom, for: key)

            cache.value = value
            store.state.atomCaches[key] = cache
            notifyChangesToObservers(of: atom, value: value)

            return value
        }
    }

    func getCache<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomCache<Node> {
        let store = getStore()

        if let cache = peekCache(of: atom, for: key) {
            return cache
        }
        else {
            let cache = AtomCache(atom: atom)
            store.state.atomCaches[key] = cache

            for observer in observers {
                observer.atomAssigned(atom: atom)
            }

            return cache
        }
    }

    func peekCache<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomCache<Node>? {
        let store = getStore()

        guard let baseCache = store.state.atomCaches[key] else {
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
            store.state.atomStates[key] = state
            return state
        }

        guard let baseState = store.state.atomStates[key] else {
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

    func notifyUpdate(for key: AtomKey, updatesChildrenOnNextRunLoop: Bool = false) {
        let store = getStore()

        // Notifying update to view subscriptions first.
        if let state = store.state.atomStates[key] {
            for subscription in ContiguousArray(state.subscriptions.values) {
                subscription.notifyUpdate()
            }
        }

        // Reset the atom value and then notify update to downstream atoms.
        func updateChildren() {
            guard let children = store.graph.children[key] else {
                return
            }

            for child in children {
                let cache = store.state.atomCaches[child]
                cache?.reset(with: self)
            }
        }

        // At the timing when `ObservableObject/objectWillChange` emits, its properties
        // have not yet been updated and are still old when dependent atoms read it.
        // As a workaround, the update is executed in the next run loop
        // so that the downstream atoms can receive the object that's already updated.
        if updatesChildrenOnNextRunLoop {
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
        updatesChildrenOnNextRunLoop: Bool = false
    ) {
        let store = getStore()
        var cache = getCache(of: atom, for: key)
        let oldValue = cache.value

        // Update the current value with the new value.
        cache.value = value
        store.state.atomCaches[key] = cache

        // Do not notify update if the new value and the old value are equivalent.
        if let oldValue = oldValue, !atom._loader.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, updatesChildrenOnNextRunLoop: updatesChildrenOnNextRunLoop)
        notifyChangesToObservers(of: atom, value: value)
    }

    func release(for key: AtomKey) {
        let store = getStore()

        // Invalidate transactions, dependencies, and the atom state.
        let dependencies = invalidate(for: key)
        let cache = store.state.atomCaches.removeValue(forKey: key)

        store.state.atomStates.removeValue(forKey: key)
        store.graph.children.removeValue(forKey: key)
        cache?.notifyUnassigned(to: observers)

        // Check if the dependencies are releasable.
        checkReleaseDependencies(dependencies, for: key)
    }

    func checkRelease(for key: AtomKey) {
        let store = getStore()

        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        let shouldKeepAlive = store.state.atomCaches[key]?.shouldKeepAlive ?? false
        let shouldRelease =
            !shouldKeepAlive
            && (store.graph.children[key]?.isEmpty ?? true)
            && (store.state.atomStates[key]?.subscriptions.isEmpty ?? true)

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
        store.state.atomStates[key]?.transaction?.terminate()
        return store.graph.dependencies.removeValue(forKey: key) ?? []
    }

    func notifyChangesToObservers<Node: Atom>(of atom: Node, value: Node.Loader.Value) {
        guard !observers.isEmpty else {
            return
        }

        let snapshot = Snapshot(atom: atom, value: value) {
            let key = AtomKey(atom)
            update(atom: atom, for: key, with: value)
            checkRelease(for: key)
        }

        for observer in observers {
            observer.atomChanged(snapshot: snapshot)
        }
    }

    func getStore() -> Store {
        if let store = weakStore {
            return store
        }

        assertionFailure(
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
            consider using `AtomRelay` to pass it.
            That happens when using SwiftUI view wrapped with `UIHostingController`.

            ```
            struct ExampleView: View {
                @ViewContext
                var context

                var body: some View {
                    UIViewWrappingView {
                        AtomRelay(context) {
                            WrappedView()
                        }
                    }
                }
            }
            ```

            The modal screen presented by the `.sheet` modifier or etc, inherits from the environment values,
            but only in iOS14, there is a bug where the environment values will be dismantled during it is
            dismissing. This also can be avoided by using `AtomRelay` to explicitly inherit from it.

            ```
            .sheet(isPresented: ...) {
                AtomRelay(context) {
                    ExampleView()
                }
            }
            ```
            """
        )

        return Store()
    }
}
