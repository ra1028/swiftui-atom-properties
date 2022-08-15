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
    func read<Node: Atom>(_ atom: Node) -> Node.State.Value {
        getValue(of: atom)
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        // Do nothing if the atom is not yet to be watched.
        guard let oldValue = getCachedState(of: atom)?.value else {
            return
        }

        let context = AtomRelationContext(atom: atom, store: self)

        atom.willSet(newValue: value, oldValue: oldValue, context: context)
        update(atom: atom, with: value)
        atom.didSet(newValue: value, oldValue: oldValue, context: context)
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.State.Value {
        guard let store = store else {
            return getNewValue(of: atom)
        }

        let key = AtomKey(atom)
        let subscriptionKey = container.key
        let subscription = Subscription(notifyUpdate: notifyUpdate) { [weak store] in
            // Remove subscription from the store.
            store?.state.removeSubscription(for: subscriptionKey, subscribedFor: key)
            // Release the atom if it is no longer watched to.
            checkForRelease(for: key)
        }

        registerIfAbsent(atom: atom)

        // Assign subscription to the container so the caller side can unsubscribe.
        container.insert(subscription: subscription, for: key)

        // Assign subscription to the store.
        store.state.insert(subscription: subscription, for: subscriptionKey, subscribeFor: key)

        return getValue(of: atom)
    }

    @usableFromInline
    func watch<Node: Atom, Dependent: Atom>(
        _ atom: Node,
        dependent: Dependent
    ) -> Node.State.Value {
        guard let store = store else {
            return getNewValue(of: atom)
        }

        let key = AtomKey(atom)
        let dependentKey = AtomKey(dependent)

        registerIfAbsent(atom: atom)
        store.state.insert(pendingDependency: key, for: dependentKey)

        return getValue(of: atom)
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue {
        let key = AtomKey(atom)
        let context = makeValueContext(for: atom)
        let value: Node.State.Value

        if let state = store?.state.atomState(for: key) {
            state.terminate()
        }

        if let overrideValue = overrides?.value(for: atom) {
            value = await atom.value.refresh(context: context, with: overrideValue)
        }
        else {
            value = await atom.value.refresh(context: context)
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
        state.terminate()
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
    func addTermination<Node: Atom>(for atom: Node, _ termination: @MainActor @escaping () -> Void) {
        let key = AtomKey(atom)

        guard let state = store?.state.atomState(for: key) else {
            return termination()
        }

        state.addTermination(termination)
    }

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

    func makeValueContext<Node: Atom>(for atom: Node) -> AtomValueContext<Node.State.Value> {
        AtomValueContext(
            atomContext: AtomRelationContext(atom: atom, store: self),
            commitPendingDependencies: {
                commitPendingDependencies(for: atom)
            },
            update: { value, updatesDependentsOnNextRunLoop in
                update(
                    atom: atom,
                    with: value,
                    updatesDependentsOnNextRunLoop: updatesDependentsOnNextRunLoop
                )
            },
            addTermination: { termination in
                addTermination(for: atom, termination)
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

    func commitPendingDependencies<Node: Atom>(for atom: Node) {
        guard let store = store else {
            return
        }

        let key = AtomKey(atom)
        let dependencies = store.state.removePendingDependencies(for: key)
        let oldDependencies = store.graph.removeDependencies(for: key)
        let obsoletedDependencies = oldDependencies.subtracting(dependencies)

        for dependency in dependencies {
            store.graph.addEdge(for: dependency, to: key)
        }

        // Recursively release dependencies.
        for dependency in obsoletedDependencies {
            // Unlink this atom from the upstream atoms.
            store.graph.remove(child: key, for: dependency)

            // Release the upstream atoms as well.
            checkForRelease(for: dependency)
        }
    }

    func getValue<Node: Atom>(of atom: Node) -> Node.State.Value {
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

    func getNewValue<Node: Atom>(of atom: Node) -> Node.State.Value {
        let context = makeValueContext(for: atom)
        let value: Node.State.Value

        if let overrideValue = overrides?.value(for: atom) {
            // Set the override value.
            value = atom.value.lookup(context: context, with: overrideValue)
        }
        else {
            value = atom.value.get(context: context)
        }

        return value
    }

    func getCachedState<Node: Atom>(of atom: Node) -> ConcreteAtomState<Node>? {
        let key = AtomKey(atom)

        guard let baseState = store?.state.atomState(for: key) else {
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
        for subscription in store.state.subscriptions(for: key) {
            subscription.notifyUpdate()
        }

        // Notify update to downstream atoms.
        func notifyUpdateToDependents() {
            for child in store.graph.children(for: key) {
                if let state = store.state.atomState(for: child) {
                    state.terminate()
                    state.renew(with: self)
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
        with value: Node.State.Value,
        updatesDependentsOnNextRunLoop: Bool = false
    ) {
        guard let state = getCachedState(of: atom) else {
            return
        }

        let oldValue = state.value
        state.value = value

        // Do not notify update if the value is equivalent to the old value.
        if let oldValue = oldValue, !atom.value.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        let key = AtomKey(atom)

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, updatesDependentsOnNextRunLoop: updatesDependentsOnNextRunLoop)

        // Notify new value.
        notifyChangesToObservers(of: atom, value: value)
    }

    func checkForRelease(for key: AtomKey) {
        guard let store = store else {
            return
        }

        // Do not release atoms marked as `KeepAlive`.
        let shouldKeepAlive = store.state.atomState(for: key)?.shouldKeepAlive ?? false
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

        if let state = store.state.removeAtomState(for: key) {
            state.terminate()
            state.notifyUnassigned(to: observers)
        }

        store.graph.removeChildren(for: key)
        store.state.removeSubscriptions(for: key)

        let dependencies = store.graph.removeDependencies(for: key)
        let pendeingDependencies = store.state.removePendingDependencies(for: key)

        // Recursively release dependencies.
        for dependency in dependencies.union(pendeingDependencies) {
            // Unlink this atom from the upstream atoms.
            store.graph.remove(child: key, for: dependency)

            // Release the upstream atoms as well.
            checkForRelease(for: dependency)
        }
    }

    func notifyChangesToObservers<Node: Atom>(of atom: Node, value: Node.State.Value) {
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
