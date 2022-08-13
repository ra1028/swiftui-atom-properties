@MainActor
internal final class AtomState<Node: Atom>: AtomStateBase {
    let atom: Node
    var value: Node.State.Value?
    var terminations = ContiguousArray<Termination>()

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

@MainActor
internal protocol AtomStateBase: AnyObject {
    var shouldKeepAlive: Bool { get }
    var terminations: ContiguousArray<Termination> { get set }

    func renew(with store: RootAtomStore)
    func notifyUnassigned(to observers: [AtomObserver])
}
