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

        let context = prepareTransaction(for: atom)

        context.transaction { context in
            atom.willSet(newValue: value, oldValue: oldValue, context: context)
            update(atom: atom, with: value)
            atom.didSet(newValue: value, oldValue: oldValue, context: context)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        guard !transaction.isTerminated else {
            return getNewValue(for: atom)
        }

        let store = getStore()
        let dependencyKey = AtomKey(atom)

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

            // Remove subscription from the store.
            store.state.subscriptions[key]?.removeValue(forKey: subscriptionKey)
            // Release the atom if it is no longer watched to.
            checkRelease(for: key)
        }

        registerIfAbsent(atom: atom)

        // Assign subscription to the container so the caller side can unsubscribe.
        container.subscriptions[key] = subscription

        // Assign subscription to the store.
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

        update(atom: atom, with: value)
        return value
    }

    @usableFromInline
    func reset<Node: Atom>(_ atom: Node) {
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
        let isNewlyRegistered = store.state.atomStates.insertValueIfAbsent(
            forKey: key,
            default: ConcreteAtomState(atom: atom)
        )

        if isNewlyRegistered {
            // Notify atom registration to observers.
            for observer in observers {
                observer.atomAssigned(atom: atom)
            }
        }
    }

    /// Returns a loader context that will not accept subsequent operations to the store when terminated.
    func prepareTransaction<Node: Atom>(for atom: Node) -> AtomLoaderContext<Node.Loader.Value> {
        let store = getStore()
        let key = AtomKey(atom)
        let oldDependencies = invalidate(for: key)
        let transaction = Transaction(key: key) {
            let store = getStore()
            let dependencies = store.graph.dependencies[key] ?? []
            let obsoletedDependencies = oldDependencies.subtracting(dependencies)

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

        if let value = state?.value {
            return value
        }

        let key = AtomKey(atom)
        let value = getNewValue(for: atom)

        state?.value = value
        store.state.atomStates[key] = state

        // Notify value changes.
        notifyChangesToObservers(of: atom, value: value)

        return value
    }

    func getNewValue<Node: Atom>(for atom: Node) -> Node.Loader.Value {
        let context = prepareTransaction(for: atom)
        let value: Node.Loader.Value

        if let overrideValue = overrides?.value(for: atom) {
            // Set the override value.
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

            // Release invalid registration.
            release(for: key)
            return nil
        }

        return state
    }

    func notifyUpdate(for key: AtomKey, updatesChildrenOnNextRunLoop: Bool = false) {
        let store = getStore()

        // Notifying update for view subscriptions takes precedence.
        if let subscriptions = store.state.subscriptions[key].map({ ContiguousArray($0.values) }) {
            for subscription in subscriptions {
                subscription.notifyUpdate()
            }
        }

        // Notify update to downstream atoms.
        func notifyUpdateToChildren() {
            guard let children = store.graph.children[key] else {
                return
            }

            for child in children {
                let state = store.state.atomStates[child]
                state?.reset(with: self)
            }
        }

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

        state?.value = value
        store.state.atomStates[key] = state

        // Do not notify update if the value is equivalent to the old value.
        if let oldValue = oldValue, !atom._loader.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, updatesChildrenOnNextRunLoop: updatesChildrenOnNextRunLoop)

        // Notify new value.
        notifyChangesToObservers(of: atom, value: value)
    }

    func checkRelease(for key: AtomKey) {
        let store = getStore()

        // Do not release atoms marked as `KeepAlive`.
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

    func release(for key: AtomKey) {
        let store = getStore()
        let dependencies = invalidate(for: key)
        let atomState = store.state.atomStates.removeValue(forKey: key)

        store.graph.children.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)
        atomState?.notifyUnassigned(to: observers)

        checkReleaseDependencies(dependencies, for: key)
    }

    func checkReleaseDependencies(_ dependencies: Set<AtomKey>, for key: AtomKey) {
        let store = getStore()

        // Recursively release dependencies.
        for dependency in dependencies {
            store.graph.children[dependency]?.remove(key)
            checkRelease(for: dependency)
        }
    }

    /// Terminates an atom associated with the given key bye the following steps.
    ///
    /// 1. Run all termination processes of the atom.
    /// 2. Remove the current transaction and mark it as terminated.
    /// 3. Temporarily remove the dependencies.
    func invalidate(for key: AtomKey) -> Set<AtomKey> {
        let store = getStore()

        // Remove the current transaction and then terminate to prevent current transaction
        // to watch new values or add terminations.
        store.state.transactions.removeValue(forKey: key)?.terminate()
        // Remove dependencies but do not release them recursively.
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
