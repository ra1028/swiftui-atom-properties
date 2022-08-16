import Foundation

@usableFromInline
@MainActor
internal struct RootAtomStore {
    private weak var store: Store?
    private let overrides: Overrides?
    private let observers: [AtomObserver]

    init(
        store: Store,
        overrides: Overrides? = nil,
        observers: [AtomObserver] = []
    ) {
        self.store = store
        self.overrides = overrides
        self.observers = observers
    }
}

extension RootAtomStore: AtomStore {
    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        getValue(of: atom)
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        // Do nothing if the atom is not yet to be watched.
        guard let oldValue = getCachedState(of: atom)?.value else {
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
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        guard let store = store else {
            return getNewValue(of: atom)
        }

        let key = AtomKey(atom)
        let subscriptionKey = container.key
        let subscription = Subscription(notifyUpdate: notifyUpdate) { [weak store] in
            // Remove subscription from the store.
            store?.state.subscriptions[key]?.removeValue(forKey: subscriptionKey)
            // Release the atom if it is no longer watched to.
            checkRelease(for: key)
        }

        registerIfAbsent(atom: atom)

        // Assign subscription to the container so the caller side can unsubscribe.
        container.insert(subscription: subscription, for: key)

        // Assign subscription to the store.
        store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: subscriptionKey)

        return getValue(of: atom)
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        let key = AtomKey(atom)

        registerIfAbsent(atom: atom)
        transaction.dependencies.insert(key)
        return getValue(of: atom)
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let key = AtomKey(atom)
        let context = prepareTransaction(for: atom)
        let value: Node.Loader.Value

        terminate(for: key)

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
        guard let state = getCachedState(of: atom) else {
            return
        }

        let key = AtomKey(atom)

        state.value = nil
        terminate(for: key)
        notifyUpdate(for: key)
    }

    @usableFromInline
    func relay(observers: [AtomObserver]) -> AtomStore {
        Self(
            store: store,
            overrides: overrides,
            observers: self.observers + observers
        )
    }
}

internal extension RootAtomStore {
    @usableFromInline
    func renew<Node: Atom>(atom: Node) {
        let value = getNewValue(of: atom)
        update(atom: atom, with: value)
    }
}

private extension RootAtomStore {
    init(
        store: Store?,
        overrides: Overrides? = nil,
        observers: [AtomObserver] = []
    ) {
        self.store = store
        self.overrides = overrides
        self.observers = observers
    }

    func prepareTransaction<Node: Atom>(for atom: Node) -> AtomLoaderContext<Node.Loader.Value> {
        let key = AtomKey(atom)
        let transaction = Transaction()

        store?.state.currentTransaction[key] = transaction

        return AtomLoaderContext(
            store: self,
            transaction: transaction,
            update: { value, updatesDependentsOnNextRunLoop in
                update(
                    atom: atom,
                    with: value,
                    updatesDependentsOnNextRunLoop: updatesDependentsOnNextRunLoop
                )
            },
            commitTransaction: { transaction in
                commitTransaction(transaction, for: atom)
            }
        )
    }

    func registerIfAbsent<Node: Atom>(atom: Node) {
        guard let store = store else {
            return
        }

        let key = AtomKey(atom)
        let isNewlyRegistered = store.state.addAtomStateIfAbsent(for: key) {
            ConcreteAtomState(atom: atom)
        }

        if isNewlyRegistered {
            // Notify atom registration to observers.
            for observer in observers {
                observer.atomAssigned(atom: atom)
            }
        }
    }

    func commitTransaction<Node: Atom>(_ transaction: Transaction, for atom: Node) {
        guard let store = store, !transaction.isClosed else {
            return
        }

        let key = AtomKey(atom)
        let dependencies = transaction.dependencies
        let oldDependencies = store.graph.dependencies.removeValue(forKey: key) ?? []
        let obsoletedDependencies = oldDependencies.subtracting(dependencies)

        store.state.terminations[key, default: []].append(contentsOf: transaction.terminations)

        for dependency in dependencies {
            store.graph.addEdge(for: dependency, to: key)
        }

        for dependency in obsoletedDependencies {
            store.graph.children[dependency]?.remove(key)
            checkRelease(for: dependency)
        }
    }

    func getValue<Node: Atom>(of atom: Node) -> Node.Loader.Value {
        let state = getCachedState(of: atom)

        if let value = state?.value {
            return value
        }

        let value = getNewValue(of: atom)
        state?.value = value

        // Notify value changes.
        notifyChangesToObservers(of: atom, value: value)

        return value
    }

    func getNewValue<Node: Atom>(of atom: Node) -> Node.Loader.Value {
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

    func getCachedState<Node: Atom>(of atom: Node) -> ConcreteAtomState<Node>? {
        let key = AtomKey(atom)

        guard let baseState = store?.state.atomStates[key] else {
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

    func notifyUpdate(for key: AtomKey, updatesDependentsOnNextRunLoop: Bool = false) {
        guard let store = store else {
            return
        }

        // Notifying update for view subscriptions takes precedence.
        if let subscriptions = store.state.subscriptions[key].map({ ContiguousArray($0.values) }) {
            for subscription in subscriptions {
                subscription.notifyUpdate()
            }
        }

        // Notify update to downstream atoms.
        func notifyUpdateToDependents() {
            if let children = store.graph.children[key] {
                for child in children {
                    if let state = store.state.atomStates[child] {
                        terminate(for: child)
                        state.renew(with: self)
                    }
                }
            }
        }

        if updatesDependentsOnNextRunLoop {
            RunLoop.current.perform {
                notifyUpdateToDependents()
            }
        }
        else {
            notifyUpdateToDependents()
        }
    }

    func update<Node: Atom>(
        atom: Node,
        with value: Node.Loader.Value,
        updatesDependentsOnNextRunLoop: Bool = false
    ) {
        guard let state = getCachedState(of: atom) else {
            return
        }

        let oldValue = state.value
        state.value = value

        // Do not notify update if the value is equivalent to the old value.
        if let oldValue = oldValue, !atom._loader.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        let key = AtomKey(atom)

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, updatesDependentsOnNextRunLoop: updatesDependentsOnNextRunLoop)

        // Notify new value.
        notifyChangesToObservers(of: atom, value: value)
    }

    func checkRelease(for key: AtomKey) {
        guard let store = store else {
            return
        }

        // Do not release atoms marked as `KeepAlive`.
        let shouldKeepAlive = store.state.atomStates[key]?.shouldKeepAlive ?? false
        let shouldRelease =
            !shouldKeepAlive
            && !store.graph.hasChildren(for: key)
            && !store.state.hasSubscriptions(for: key)

        guard shouldRelease else {
            return
        }

        release(for: key)
    }

    func release(for key: AtomKey) {
        guard let store = store else {
            return
        }

        terminate(for: key)

        let dependencies = store.graph.dependencies.removeValue(forKey: key) ?? []
        let state = store.state.atomStates.removeValue(forKey: key)
        store.graph.children.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)

        state?.notifyUnassigned(to: observers)

        // Recursively release dependencies.
        for dependency in dependencies {
            store.graph.children[dependency]?.remove(key)
            checkRelease(for: dependency)
        }
    }

    func terminate(for key: AtomKey) {
        guard let store = store else {
            return
        }

        let transaction = store.state.currentTransaction.removeValue(forKey: key)
        let terminations = store.state.terminations.removeValue(forKey: key) ?? []
        let uncommitedTerminations = transaction?.terminations ?? []

        transaction?.close()

        for termination in terminations + uncommitedTerminations {
            termination()
        }
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
}
