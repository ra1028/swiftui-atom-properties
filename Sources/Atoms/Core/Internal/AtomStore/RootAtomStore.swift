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

        register(atom: atom)

        // Assign subscription to the container so the caller side can unsubscribe.
        container.insert(subscription: subscription, for: key)

        // Assign subscription to the store.
        store.state.insert(subscription: subscription, for: subscriptionKey, subscribeFor: key)

        return getValue(of: atom)
    }

    @usableFromInline
    func watch<Node: Atom, Dependent: Atom>(_ atom: Node, dependent: Dependent) -> Node.State.Value {
        guard let store = store else {
            return getNewValue(of: atom)
        }

        let key = AtomKey(atom)
        let dependentKey = AtomKey(dependent)

        register(atom: atom)
        store.graph.addEdge(for: key, to: dependentKey)

        return getValue(of: atom)
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue {
        let key = AtomKey(atom)
        let dependencies = terminate(for: key)
        let context = makeValueContext(for: atom)
        let value: Node.State.Value

        if let overrideValue = overrides?.value(for: atom) {
            value = await atom.value.refresh(context: context, with: overrideValue)
        }
        else {
            value = await atom.value.refresh(context: context)
        }

        update(atom: atom, with: value)
        releaseDependencies(of: key, dependencies: dependencies)
        return value
    }

    @usableFromInline
    func reset<Node: Atom>(_ atom: Node) {
        guard let state = getCachedState(of: atom) else {
            return
        }

        let key = AtomKey(atom)
        let dependencies = terminate(for: key)

        state.value = nil
        notifyUpdate(for: key)
        releaseDependencies(of: key, dependencies: dependencies)
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

        let termination = Termination(termination)
        state.terminations.append(termination)
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

    func register<Node: Atom>(atom: Node) {
        guard let store = store else {
            return
        }

        let key = AtomKey(atom)
        let isNewlyRegistered = store.state.addAtomStateIfNotPresent(for: key) {
            ConcreteAtomState(atom: atom)
        }

        if isNewlyRegistered {
            // Notify atom registration to observers.
            for observer in observers {
                observer.atomAssigned(atom: atom)
            }
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
                let dependencies = terminate(for: child)
                store.state.atomState(for: child)?.renew(with: self)
                releaseDependencies(of: child, dependencies: dependencies)
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

    func terminate(for key: AtomKey) -> Set<AtomKey> {
        guard let store = store else {
            return []
        }

        let state = store.state.atomState(for: key)
        let terminations = state?.terminations ?? []
        let dependencies = store.graph.removeDependencies(for: key)

        state?.terminations.removeAll()

        for termination in terminations {
            termination()
        }

        return dependencies
    }

    func checkForRelease(for key: AtomKey) {
        guard let store = store else {
            return
        }

        // Do not release atoms marked as `KeepAlive`.
        let shouldKeepAlive = store.state.atomState(for: key)?.shouldKeepAlive ?? false

        guard !shouldKeepAlive else {
            return
        }

        guard !store.graph.hasChildren(for: key) && !store.state.hasSubscriptions(for: key) else {
            return
        }

        release(for: key)
    }

    func release(for key: AtomKey) {
        guard let store = store else {
            return
        }

        let dependencies = terminate(for: key)

        store.graph.removeChildren(for: key)
        store.state.removeSubscriptions(for: key)

        // Cleanup.
        guard let state = store.state.removeAtomState(for: key) else {
            return
        }

        // Notify atom release to observers.
        state.notifyUnassigned(to: observers)

        // Recursively, release upstream atoms.
        releaseDependencies(of: key, dependencies: dependencies)
    }

    func releaseDependencies(of key: AtomKey, dependencies: Set<AtomKey>) {
        guard let store = store, !dependencies.isEmpty else {
            return
        }

        let current = store.graph.dependencies(for: key)
        let obsoleted = dependencies.subtracting(current)

        // Recursively release dependencies.
        for obsoleted in obsoleted {
            // Unlink this atom from the upstream atoms.
            store.graph.remove(child: key, for: obsoleted)

            // Release the upstream atoms as well.
            checkForRelease(for: obsoleted)
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
