import Foundation

@MainActor
internal struct Store: AtomStore {
    private(set) weak var container: StoreContainer?
    let overrides: Overrides?
    let observers: [AtomObserver]

    init(
        container: StoreContainer,
        overrides: Overrides? = nil,
        observers: [AtomObserver] = []
    ) {
        self.container = container
        self.overrides = overrides
        self.observers = observers
    }

    init(
        parent: AtomStore,
        observers: [AtomObserver]
    ) {
        self.container = parent.container
        self.overrides = parent.overrides
        self.observers = parent.observers + observers
    }

    func read<Node: Atom>(_ atom: Node) -> Node.State.Value {
        let state = getState(of: atom)
        let context = AtomStateContext(atom: atom, store: self)
        return state.value(context: context)
    }

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node) {
        // Do nothing if the host is yet to be assigned.
        guard let state = getExistingHost(of: atom)?.state else {
            return
        }

        let context = AtomStateContext(atom: atom, store: self)
        let oldValue = state.value(context: context)

        atom.willSet(newValue: value, oldValue: oldValue, context: context.atomContext)
        state.set(value: value, context: context)
        atom.didSet(newValue: value, oldValue: oldValue, context: context.atomContext)
    }

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomState {
        // Terminate the value & the ongoing task, but keep assignment until finishing refresh.
        await getHost(of: atom).withAsyncTermination { _ in
            let state = getState(of: atom)
            let context = AtomStateContext(atom: atom, store: self)

            if let value = overrides?[atom] {
                return await state.refreshOverride(with: value, context: context)
            }
            else {
                return await state.refresh(context: context)
            }
        }
    }

    func reset<Node: Atom>(_ atom: Node) {
        // Terminate the value & the ongoing task, but keep assignment until finishing notify update.
        // Do nothing if the host is yet to be assigned.
        getExistingHost(of: atom)?.withTermination {
            $0.notifyUpdate()
        }
    }

    func watch<Node: Atom>(
        _ atom: Node,
        relationship: Relationship,
        shouldNotifyAfterUpdates: Bool = false,
        notifyUpdate: @MainActor @escaping () -> Void
    ) -> Node.State.Value {
        // Assign the observation to the given relationship.
        relationship[atom] = getHost(of: atom).observe {
            if shouldNotifyAfterUpdates {
                RunLoop.current.perform {
                    notifyUpdate()
                }
            }
            else {
                notifyUpdate()
            }
        }
        return read(atom)
    }

    func watch<Node: Atom, Caller: Atom>(
        _ atom: Node,
        belongTo caller: Caller,
        shouldNotifyAfterUpdates: Bool = false
    ) -> Node.State.Value {
        let relationship = getHost(of: caller).relationship
        return watch(atom, relationship: relationship, shouldNotifyAfterUpdates: shouldNotifyAfterUpdates) {
            let oldValue = read(caller)

            // Terminate the value & the ongoing task, but keep assignment until finishing notify update.
            getHost(of: caller).withTermination { host in
                let newValue = read(caller)
                let shouldNotify = caller.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)

                if shouldNotify {
                    host.notifyUpdate()
                }
            }
        }
    }

    func notifyUpdate<Node: Atom>(_ atom: Node) {
        // Do nothing if the host is yet to be assigned.
        getExistingHost(of: atom)?.notifyUpdate()
    }

    func addTermination<Node: Atom>(_ atom: Node, termination: @MainActor @escaping () -> Void) {
        // Terminate immediately if the host is yet to be assigned.
        guard let host = getExistingHost(of: atom) else {
            return termination()
        }

        host.addTermination(termination)
    }
}

private extension Store {
    func getState<Node: Atom>(of atom: Node) -> Node.State {
        let host = getHost(of: atom)

        if let state = host.state {
            return state
        }

        let state = atom.makeState()
        host.state = state

        if let value = overrides?[atom] {
            // Set the override value.
            let context = AtomStateContext(atom: atom, store: self)
            state.override(with: value, context: context)
        }

        // Notify the initial update to observers.
        notifyChangesToObservers(of: atom, state: state)

        return state
    }

    func getHost<Node: Atom>(of atom: Node) -> AtomHost<Node.State> {
        let key = AtomKey(atom)

        // Check if the host already exists.
        if let host = getExistingHost(of: atom) {
            return host
        }

        let host = AtomHost<Node.State>()

        host.onDeinit = {
            // Cleanup the weak entry box.
            container?.entries.removeValue(forKey: key)

            // Notify the unassignment to observers.
            for observer in observers {
                observer.atomUnassigned(atom: atom)
            }
        }

        host.onUpdate = { state in
            // Notify the update to observers.
            notifyChangesToObservers(of: atom, state: state)
        }

        guard let container = container else {
            return host
        }

        if Node.shouldKeepAlive {
            // Insert the host with strong reference to keep it eternally in the current process.
            container.entries[key] = KeepAliveStoreEntry(host: host)
        }
        else {
            // Insert the host with weak reference.
            container.entries[key] = WeakStoreEntry(host: host)
        }

        // Notify the assignment to observers.
        for observer in observers {
            observer.atomAssigned(atom: atom)
        }

        return host
    }

    func getExistingHost<Node: Atom>(of atom: Node) -> AtomHost<Node.State>? {
        let key = AtomKey(atom)

        guard let base = container?.entries[key]?.host else {
            return nil
        }

        guard let host = base as? AtomHost<Node.State> else {
            assertionFailure(
                """
                The type of the given atom and the stored host did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom type: \(Node.self)
                Key type: \(type(of: atom.key))
                Host type: \(type(of: base))
                """
            )

            // Remove the existing entry as fallback.
            container?.entries.removeValue(forKey: key)
            return nil
        }

        return host
    }

    func notifyChangesToObservers<Node: Atom>(
        of atom: Node,
        state: Node.State
    ) {
        guard !observers.isEmpty else {
            return
        }

        let context = AtomStateContext(atom: atom, store: self)
        let value = state.value(context: context)
        let snapshot = Snapshot(atom: atom, value: value) {
            // Do nothing if the host is yet to be assigned.
            guard let host = getExistingHost(of: snapshot.atom), let state = host.state else {
                return
            }

            let context = AtomStateContext(atom: snapshot.atom, store: self)
            state.override(with: snapshot.value, context: context)
            host.notifyUpdate()
        }

        for observer in observers {
            observer.atomChanged(snapshot: snapshot)
        }
    }
}
