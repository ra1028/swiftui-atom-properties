@MainActor
internal protocol AtomState: AnyObject {
    var shouldKeepAlive: Bool { get }
    var terminations: ContiguousArray<Termination> { get set }

    func terminate()
    func renew(with store: RootAtomStore)
    func notifyUnassigned(to observers: [AtomObserver])
}

@MainActor
internal final class ConcreteAtomState<Node: Atom>: AtomState {
    private let atom: Node

    var value: Node.Loader.Value?
    var terminations = ContiguousArray<Termination>()

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    init(atom: Node) {
        self.atom = atom
    }

    func terminate() {
        for termination in terminations {
            termination()
        }

        terminations.removeAll()
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
