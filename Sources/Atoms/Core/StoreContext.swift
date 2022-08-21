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
        getValue(for: atom)
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        // Do nothing if the atom is not yet to be watched.
        guard let oldValue = getCachedState(for: atom)?.value else {
            return
        }

        // Note that this is a special handling for `willSet/didSet` because the dependencies of the `StateAtom`
        // can be invalidated if we call `prepareTransaction` here and there's no timing to restore them.
        // The dependencies added in `willSet/didSet` will not be released until the value is invalidated and
        // is going to be a bug, so `AtomTransactionContenxt` will no longer be passed.
        // https://github.com/ra1028/swiftui-atom-properties/issues/18
        let key = AtomKey(atom)
        let transaction = Transaction(key: key) {
            // Do nothing.
        }
        let context = AtomLoaderContext(store: self, transaction: transaction) { value, updatesChildrenOnNextRunLoop in
            update(atom: atom, with: value, updatesChildrenOnNextRunLoop: updatesChildrenOnNextRunLoop)
        }

        context.transaction { context in
            atom.willSet(newValue: value, oldValue: oldValue, context: context)
            update(atom: atom, with: value)
            atom.didSet(newValue: value, oldValue: oldValue, context: context)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        // Return a new value if the transaction is already terminated.
        guard !transaction.isTerminated else {
            return getNewValue(for: atom)
        }

        let store = getStore()
        let dependencyKey = AtomKey(atom)

        // Create and register a state if it doesn't exist yet.
        registerIfAbsent(atom: atom)

        // Add an `Edge` from the upstream to downstream.
        store.graph.dependencies[transaction.key, default: []].insert(dependencyKey)
        store.graph.children[dependencyKey, default: []].insert(transaction.key)

        return getValue(for: atom)
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        let store = getStore()
        let key = AtomKey(atom)
        let subscriptionKey = SubscriptionKey(container)
        let subscription = Subscription(notifyUpdate: notifyUpdate) { [weak store] in
            guard let store = store else {
                return
            }

            // Unsubscribe and then release the atom if it's doesn't have any subscriptions or children.
            store.state.subscriptions[key]?.removeValue(forKey: subscriptionKey)
            checkRelease(for: key)
        }

        // Create and register a state if it doesn't exist yet.
        registerIfAbsent(atom: atom)

        // Register the subscription to both the store and the container, enabling notifying updates and unsubscription.
        container.subscriptions[key] = subscription
        store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: subscriptionKey)

        return getValue(for: atom)
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let context = prepareTransaction(for: atom)
        let value: Node.Loader.Value

        if let overrideValue = overrides?.value(for: atom) {
            value = await atom._loader.refresh(context: context, with: overrideValue)
        }
        else {
            value = await atom._loader.refresh(context: context)
        }

        // Update the current value with the refresh value.
        update(atom: atom, with: value)
        return value
    }

    @usableFromInline
    func reset<Node: Atom>(_ atom: Node) {
        // Renew the value and then notify to the downstream.
        let value = getNewValue(for: atom)
        update(atom: atom, with: value)
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
    func registerIfAbsent<Node: Atom>(atom: Node) {
        let store = getStore()
        let key = AtomKey(atom)

        // Register a new state only if not yet exist.
        let isNewlyRegistered = store.state.atomStates.insertValueIfAbsent(
            forKey: key,
            default: ConcreteAtomState(atom: atom)
        )

        if isNewlyRegistered {
            for observer in observers {
                observer.atomAssigned(atom: atom)
            }
        }
    }

    func prepareTransaction<Node: Atom>(for atom: Node) -> AtomLoaderContext<Node.Loader.Value> {
        let store = getStore()
        let key = AtomKey(atom)

        // Invalidate dependencies and an ongoing transaction.
        let oldDependencies = invalidate(for: key)
        let transaction = Transaction(key: key) {
            let store = getStore()
            let dependencies = store.graph.dependencies[key] ?? []
            let obsoletedDependencies = oldDependencies.subtracting(dependencies)

            // Check if the dependencies that are no longer watched can be released.
            checkReleaseDependencies(obsoletedDependencies, for: key)
        }

        store.state.transactions[key] = transaction

        return AtomLoaderContext(store: self, transaction: transaction) { value, updatesChildrenOnNextRunLoop in
            update(atom: atom, with: value, updatesChildrenOnNextRunLoop: updatesChildrenOnNextRunLoop)
        }
    }

    func getValue<Node: Atom>(for atom: Node) -> Node.Loader.Value {
        let store = getStore()
        var state = getCachedState(for: atom)

        // Return the cached value is exists otherwise, get a new value and then cache it.
        if let value = state?.value {
            return value
        }
        else {
            let key = AtomKey(atom)
            let value = getNewValue(for: atom)

            state?.value = value
            store.state.atomStates[key] = state

            notifyChangesToObservers(of: atom, value: value)
            return value
        }
    }

    func getNewValue<Node: Atom>(for atom: Node) -> Node.Loader.Value {
        let context = prepareTransaction(for: atom)
        let value: Node.Loader.Value

        if let overrideValue = overrides?.value(for: atom) {
            value = atom._loader.handle(context: context, with: overrideValue)
        }
        else {
            value = atom._loader.get(context: context)
        }

        return value
    }

    func getCachedState<Node: Atom>(for atom: Node) -> ConcreteAtomState<Node>? {
        let store = getStore()
        let key = AtomKey(atom)

        guard let baseState = store.state.atomStates[key] else {
            return nil
        }

        guard let state = baseState as? ConcreteAtomState<Node> else {
            assertionFailure(
                """
                The type of the given atom's value and the cached value did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom type: \(Node.self)
                Key type: \(type(of: atom.key))
                Invalid state type: \(type(of: baseState))
                """
            )

            // Release the invalid registration.
            release(for: key)
            return nil
        }

        return state
    }

    func notifyUpdate(for key: AtomKey, updatesChildrenOnNextRunLoop: Bool = false) {
        let store = getStore()

        // Notifying update to view subscriptions first.
        if let subscriptions = store.state.subscriptions[key].map({ ContiguousArray($0.values) }) {
            for subscription in subscriptions {
                subscription.notifyUpdate()
            }
        }

        // Reset the atom value and then notify update to downstream atoms.
        func notifyUpdateToChildren() {
            guard let children = store.graph.children[key] else {
                return
            }

            for child in children {
                let state = store.state.atomStates[child]
                state?.reset(with: self)
            }
        }

        // At the timing when `ObservableObject/objectWillChange` emits, its properties
        // have not yet been updated and are still old when the dependent atom reads it.
        // As a workaround, the update is executed in the next run loop
        // so that the downstream atoms can receive the object that's already updated.
        if updatesChildrenOnNextRunLoop {
            RunLoop.current.perform {
                notifyUpdateToChildren()
            }
        }
        else {
            notifyUpdateToChildren()
        }
    }

    func update<Node: Atom>(
        atom: Node,
        with value: Node.Loader.Value,
        updatesChildrenOnNextRunLoop: Bool = false
    ) {
        let store = getStore()
        let key = AtomKey(atom)
        var state = getCachedState(for: atom)
        let oldValue = state?.value

        // Update the current value with the new value.
        state?.value = value
        store.state.atomStates[key] = state

        // Do not notify update if the new value is equivalent to the old value.
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
        let atomState = store.state.atomStates.removeValue(forKey: key)

        // Cleanup downstream edges.
        store.graph.children.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)
        atomState?.notifyUnassigned(to: observers)

        // Check if the dependencies are releasable.
        checkReleaseDependencies(dependencies, for: key)
    }

    func checkRelease(for key: AtomKey) {
        let store = getStore()

        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        let shouldKeepAlive = store.state.atomStates[key]?.shouldKeepAlive ?? false
        let shouldRelease =
            !shouldKeepAlive
            && store.graph.children.isEmptyOrNil(forKey: key)
            && store.state.subscriptions.isEmptyOrNil(forKey: key)

        guard shouldRelease else {
            return
        }

        release(for: key)
    }

    func checkReleaseDependencies(_ dependencies: Set<AtomKey>, for key: AtomKey) {
        let store = getStore()

        // Recursively release dependencies while unlinking the dependent from the dependencies.
        for dependency in dependencies {
            store.graph.children[dependency]?.remove(key)
            checkRelease(for: dependency)
        }
    }

    func invalidate(for key: AtomKey) -> Set<AtomKey> {
        let store = getStore()

        // Remove the current transaction and then terminate to prevent current transaction
        // to watch new values or add terminations.
        // Then, temporarily remove dependencies but do not release them recursively here.
        store.state.transactions.removeValue(forKey: key)?.terminate()
        return store.graph.dependencies.removeValue(forKey: key) ?? []
    }

    func notifyChangesToObservers<Node: Atom>(of atom: Node, value: Node.Loader.Value) {
        guard !observers.isEmpty else {
            return
        }

        let snapshot = Snapshot(atom: atom, value: value) {
            update(atom: atom, with: value)
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

private extension Dictionary {
    func isEmptyOrNil(forKey key: Key) -> Bool where Value: Collection {
        self[key]?.isEmpty ?? true
    }

    mutating func insertValueIfAbsent(forKey key: Key, default defaultValue: @autoclosure () -> Value) -> Bool {
        withUnsafeMutablePointer(to: &self[key]) { pointer in
            guard pointer.pointee == nil else {
                return false
            }
            pointer.pointee = defaultValue()
            return true
        }
    }
}
