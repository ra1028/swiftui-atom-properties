@MainActor
internal protocol AtomState {
    var shouldKeepAlive: Bool { get }

    func reset(with store: StoreContext)
    func notifyUnassigned(to observers: [AtomObserver])
}

@MainActor
internal struct ConcreteAtomState<Node: Atom>: AtomState {
    var atom: Node
    var value: Node.Loader.Value?

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    func reset(with store: StoreContext) {
        store.reset(atom)
    }

    func notifyUnassigned(to observers: [AtomObserver]) {
        for observer in observers {
            observer.atomUnassigned(atom: atom)
        }
    }
}
