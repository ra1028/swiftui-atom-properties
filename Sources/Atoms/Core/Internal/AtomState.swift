@MainActor
internal protocol AtomState: AnyObject {
    var shouldKeepAlive: Bool { get }

    func renew(with store: RootAtomStore)
    func terminate()
    func addTermination(_ termination: @MainActor @escaping () -> Void)
    func notifyUnassigned(to observers: [AtomObserver])
}

@MainActor
internal final class ConcreteAtomState<Node: Atom>: AtomState {
    private let atom: Node
    private var terminations = ContiguousArray<Termination>()

    var value: Node.State.Value?

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    init(atom: Node) {
        self.atom = atom
    }

    func renew(with store: RootAtomStore) {
        store.renew(atom: atom)
    }

    func terminate() {
        for termination in terminations {
            termination()
        }

        terminations.removeAll()
    }

    func addTermination(_ termination: @MainActor @escaping () -> Void) {
        let termination = Termination(termination)
        terminations.append(termination)
    }

    func notifyUnassigned(to observers: [AtomObserver]) {
        for observer in observers {
            observer.atomUnassigned(atom: atom)
        }
    }
}
