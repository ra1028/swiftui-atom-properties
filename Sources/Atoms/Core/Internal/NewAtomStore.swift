@usableFromInline
internal final class NewAtomStore {
    var graph = Graph()
    var state = StoreState()
}

@usableFromInline
@MainActor
internal protocol AtomStoreInteractor {
    func read<Node: Atom>(_ atom: Node) -> Node.State.Value

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node)

    func watch<Node: Atom, Downstream: Atom>(_ atom: Node, downstream: Downstream) -> Node.State.Value

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.State.Value

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue

    func reset<Node: Atom>(_ atom: Node)

    func addTermination<Node: Atom>(for atom: Node, _ termination: @MainActor @escaping () -> Void)

    func relay(observers: [AtomObserver]) -> AtomStoreInteractor
}

@usableFromInline
internal struct RootAtomStoreInteractor: AtomStoreInteractor {
    private weak var store: NewAtomStore?
    private let overrides: Overrides?
    private let observers: [AtomObserver]

    init(
        store: NewAtomStore,
        overrides: Overrides? = nil,
        observers: [AtomObserver] = []
    ) {
        self.store = store
        self.overrides = overrides
        self.observers = observers
    }

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
            store?.state.subscriptions[key]?.removeValue(forKey: subscriptionKey)
            // Release the atom if it is no longer watched to.
            checkAndRelease(for: key)
        }

        register(atom: atom)

        // Assign subscription to the container so the caller side can unsubscribe.
        container.assign(subscription: subscription, for: key)

        // Assign subscription to the store.
        store.state.subscriptions[key, default: [:]][subscriptionKey] = subscription

        return getValue(of: atom)
    }

    @usableFromInline
    func watch<Node: Atom, Downstream: Atom>(_ atom: Node, downstream: Downstream) -> Node.State.Value {
        guard let store = store else {
            return getNewValue(of: atom)
        }

        let key = AtomKey(atom)
        let downstreamKey = AtomKey(downstream)

        register(atom: atom)

        // Add an edge reference each other.
        store.graph.nodes[key, default: []].insert(downstreamKey)
        store.graph.dependencies[downstreamKey, default: []].insert(key)

        return getValue(of: atom)
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue {
        // Release the value & the ongoing task, but keep upstream atoms alive until finishing refresh.
        let context = makeValueContext(for: atom)
        let value: Node.State.Value

        if let overrideValue = overrides?[atom] {
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
        let key = AtomKey(atom)
        renew(for: key, forcesUpdate: true)
    }

    @usableFromInline
    func addTermination<Node: Atom>(for atom: Node, _ termination: @MainActor @escaping () -> Void) {
        guard let store = store else {
            return termination()
        }

        let key = AtomKey(atom)
        let termination = Termination(termination)

        store.state.atomStates[key]?.terminations.append(termination)
    }

    @usableFromInline
    func relay(observers: [AtomObserver]) -> AtomStoreInteractor {
        Self(
            store: store,
            overrides: overrides,
            observers: self.observers + observers
        )
    }
}

private extension RootAtomStoreInteractor {
    init(
        store: NewAtomStore?,
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
            update: { value in
                update(atom: atom, with: value)
            },
            addTermination: { termination in
                addTermination(for: atom, termination)
            }
        )
    }

    func register<Node: Atom>(atom: Node) {
        let key = AtomKey(atom)

        guard let store = store, store.state.atomStates[key] == nil else {
            return
        }

        // Register new state.
        store.state.atomStates[key] = AtomState(atom: atom)

        // Notify atom registration to observers.
        for observer in observers {
            observer.atomAssigned(atom: atom)
        }
    }

    func getValue<Node: Atom>(of atom: Node) -> Node.State.Value {
        if let value = getCachedState(of: atom)?.value {
            return value
        }

        let value = getNewValue(of: atom)
        let state = getCachedState(of: atom)

        state?.value = value

        // Notify value changes.
        notifyChangesToObservers(of: atom, value: value)

        return value
    }

    func getNewValue<Node: Atom>(of atom: Node) -> Node.State.Value {
        let context = makeValueContext(for: atom)
        let value: Node.State.Value

        if let overrideValue = overrides?[atom] {
            // Set the override value.
            value = overrideValue
            atom.value.handleUpdates(context: context, with: value)
        }
        else {
            value = atom.value.get(context: context)
        }

        return value
    }

    func getCachedState<Node: Atom>(of atom: Node) -> AtomState<Node>? {
        let key = AtomKey(atom)

        guard let baseState = store?.state.atomStates[key] else {
            return nil
        }

        guard let state = baseState as? AtomState<Node> else {
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

    func update<Node: Atom>(atom: Node, with value: Node.State.Value) {
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
        notifyUpdate(for: key)

        // Notify new value.
        notifyChangesToObservers(of: atom, value: value)
    }

    func notifyUpdate(for key: AtomKey) {
        guard let store = store else {
            return
        }

        // Notifying update for view subscriptions takes precedence.
        if let subscriptions = store.state.subscriptions[key] {
            for subscription in subscriptions.values {
                subscription.notifyUpdate()
            }
        }

        // Notify update to downstream atoms.
        if let nodes = store.graph.nodes[key] {
            for node in nodes {
                renew(for: node, forcesUpdate: false)
            }
        }
    }

    func renew(for key: AtomKey, forcesUpdate: Bool) {
        guard let store = store, let state = store.state.atomStates[key] else {
            return
        }

        // Remove dependencies.
        let dependencies = store.graph.dependencies.removeValue(forKey: key) ?? []

        // Terminate.
        for termination in state.terminations {
            termination()
        }

        // Remove terminations.
        state.terminations.removeAll()

        if forcesUpdate {
            notifyUpdate(for: key)
        }
        else {
            let shouldNotifyUpdate = state.renew(with: self)

            if shouldNotifyUpdate {
                notifyUpdate(for: key)
            }
        }

        releaseDependencies(of: key, dependencies: dependencies)
    }

    func checkAndRelease(for key: AtomKey) {
        guard let store = store  else {
            return
        }

        // Do not release atoms marked as `KeepAlive`.
        let shouldKeepAlive = store.state.atomStates[key]?.shouldKeepAlive ?? false

        guard !shouldKeepAlive else {
            return
        }

        /// `true` if the atom has no downstream atoms.
        let hasNoDependents = store.graph.nodes[key]?.isEmpty ?? true
        /// `true` if the atom is not subscribed by views.
        let hasNoSubscriptions = store.state.subscriptions[key]?.isEmpty ?? true

        if hasNoDependents {
            store.graph.nodes.removeValue(forKey: key)
        }

        if hasNoSubscriptions {
            store.state.subscriptions.removeValue(forKey: key)
        }

        guard hasNoDependents && hasNoSubscriptions else {
            return
        }

        release(for: key)
    }

    /// Release an atom associated by the specified key and return its dependencies.
    func release(for key: AtomKey) {
        guard let store = store else {
            return
        }

        // Cleanup.
        guard let state = store.state.atomStates.removeValue(forKey: key) else {
            return
        }

        // Remove dependencies.
        let dependencies = store.graph.dependencies.removeValue(forKey: key) ?? []

        // Terminate.
        for termination in state.terminations {
            termination()
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

        let current = store.graph.dependencies[key] ?? []
        let obsoleted = dependencies.subtracting(current)

        // Recursively release dependencies.
        for obsoleted in obsoleted {
            // Remove this atom from the upstream atoms.
            store.graph.nodes[obsoleted]?.remove(key)

            // Release the upstream atoms as well.
            checkAndRelease(for: obsoleted)
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
