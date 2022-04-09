@MainActor
internal struct Store: AtomStore {
    private(set) weak var container: StoreContainer?
    let overrides: AtomOverrides?
    let observers: [AtomObserver]

    init(
        container: StoreContainer,
        overrides: AtomOverrides? = nil,
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

    func read<Node: Atom>(_ atom: Node) -> Node.Hook.Value {
        let coordinator = getCoordinator(of: atom) { coordinator in
            let context = AtomHookContext(atom: atom, coordinator: coordinator, store: self)

            // Ensure that the atom is setup to have an initial value when it is first created.
            if let value = overrides?[atom] {
                // Set the override value.
                atom.hook.updateOverride(context: context, with: value)
            }
            else {
                // Update the atom to have an initial value.
                atom.hook.update(context: context)
            }

            // Notify the initial update to observers.
            notifyObserversOfUpdate(of: atom, coordinator: coordinator)
        }
        let context = AtomHookContext(atom: atom, coordinator: coordinator, store: self)

        return atom.hook.value(context: context)
    }

    func set<Node: Atom>(_ value: Node.Hook.Value, for atom: Node) where Node.Hook: AtomStateHook {
        // Do nothing if the host is yet to be assigned.
        guard let coordinator = existingHost(of: atom)?.coordinator else {
            return
        }

        let context = AtomHookContext(atom: atom, coordinator: coordinator, store: self)
        let oldValue = atom.hook.value(context: context)

        atom.hook.willSet(newValue: value, oldValue: oldValue, context: context)
        atom.hook.set(value: value, context: context)
        atom.hook.didSet(newValue: value, oldValue: oldValue, context: context)
    }

    func refresh<Node: Atom>(_ atom: Node) async -> Node.Hook.Value where Node.Hook: AtomRefreshableHook {
        // Terminate the value & the ongoing task, but keep assignment until finishing refresh.
        await host(of: atom).withAsyncTermination { _ in
            let coordinator = getCoordinator(of: atom)
            let context = AtomHookContext(atom: atom, coordinator: coordinator, store: self)

            if let value = overrides?[atom] {
                return await atom.hook.refreshOverride(context: context, with: value)
            }
            else {
                return await atom.hook.refresh(context: context)
            }
        }
    }

    func reset<Node: Atom>(_ atom: Node) {
        // Terminate the value & the ongoing task, but keep assignment until finishing notify update.
        // Do nothing if the host is yet to be assigned.
        existingHost(of: atom)?.withTermination {
            $0.notifyUpdate()
        }
    }

    func watch<Node: Atom>(
        _ atom: Node,
        relationship: Relationship,
        notifyUpdate: @MainActor @escaping () -> Void
    ) -> Node.Hook.Value {
        // Assign the observation to the given relationship.
        relationship[atom] = host(of: atom).observe(notifyUpdate)
        return read(atom)
    }

    func watch<Node: Atom, Caller: Atom>(_ atom: Node, belongTo caller: Caller) -> Node.Hook.Value {
        watch(atom, relationship: host(of: caller).relationship) {
            let oldValue = read(caller)

            // Terminate the value & the ongoing task, but keep assignment until finishing notify update.
            host(of: caller).withTermination { host in
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
        existingHost(of: atom)?.notifyUpdate()
    }

    func addTermination<Node: Atom>(_ atom: Node, termination: @MainActor @escaping () -> Void) {
        // Terminate immediately if the host is yet to be assigned.
        guard let host = existingHost(of: atom) else {
            return termination()
        }

        host.addTermination(termination)
    }

    func restore<Node: Atom>(snapshot: Snapshot<Node>) {
        // Do nothing if the host is yet to be assigned.
        guard let host = existingHost(of: snapshot.atom), let coordinator = host.coordinator else {
            return
        }

        let context = AtomHookContext(
            atom: snapshot.atom,
            coordinator: coordinator,
            store: self
        )

        snapshot.atom.hook.updateOverride(context: context, with: snapshot.value)
        host.notifyUpdate()
    }
}

private extension Store {
    func getCoordinator<Node: Atom>(
        of atom: Node,
        initialize: ((Node.Hook.Coordinator) -> Void)? = nil
    ) -> Node.Hook.Coordinator {
        let host = host(of: atom)

        if let coordinator = host.coordinator {
            return coordinator
        }

        let coordinator = atom.hook.makeCoordinator()
        host.coordinator = coordinator
        initialize?(coordinator)

        return coordinator
    }

    func host<Node: Atom>(of atom: Node) -> AtomHost<Node.Hook.Coordinator> {
        let key = AtomKey(atom)

        // Check if the host already exists.
        if let host = existingHost(of: atom) {
            return host
        }

        let host = AtomHost<Node.Hook.Coordinator>()

        host.onDeinit = {
            // Cleanup the weak entry box.
            container?.entries.removeValue(forKey: key)

            // Notify the unassignment to observers.
            for observer in observers {
                observer.atomUnassigned(atom: atom)
            }
        }

        host.onUpdate = { coordinator in
            // Notify the update to observers.
            notifyObserversOfUpdate(of: atom, coordinator: coordinator)
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

    func existingHost<Node: Atom>(of atom: Node) -> AtomHost<Node.Hook.Coordinator>? {
        let key = AtomKey(atom)

        guard let base = container?.entries[key]?.host else {
            return nil
        }

        guard let host = base as? AtomHost<Node.Hook.Coordinator> else {
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

    func notifyObserversOfUpdate<Node: Atom>(
        of atom: Node,
        coordinator: Node.Hook.Coordinator
    ) {
        guard !observers.isEmpty else {
            return
        }

        let context = AtomHookContext(atom: atom, coordinator: coordinator, store: self)
        let snapshot = Snapshot(atom: atom, value: atom.hook.value(context: context), store: self)

        for observer in observers {
            observer.atomChanged(snapshot: snapshot)
        }
    }
}
