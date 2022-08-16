@MainActor
internal protocol AtomState: AnyObject {
    var shouldKeepAlive: Bool { get }

    func renew(with store: RootAtomStore)
    func notifyUnassigned(to observers: [AtomObserver])
}

@MainActor
internal final class ConcreteAtomState<Node: Atom>: AtomState {
    private let atom: Node

    var value: Node.Loader.Value?

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    init(atom: Node) {
        self.atom = atom
    }

    func renew(with store: RootAtomStore) {
        store.renew(atom: atom)
    }

    func notifyUnassigned(to observers: [AtomObserver]) {
        for observer in observers {
            observer.atomUnassigned(atom: atom)
        }
    }
}
