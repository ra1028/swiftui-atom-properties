@MainActor
internal final class AtomState<Node: Atom>: AtomStateBase {
    var atom: Node
    var value: Node.State.Value?
    var terminations = ContiguousArray<Termination>()

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    init(atom: Node) {
        self.atom = atom
    }

    func renewValue(with store: RootAtomStore) -> Bool {
        guard let oldValue = value else {
            return true
        }

        value = nil
        let newValue = store.read(atom)
        value = newValue

        return atom.value.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)
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

    /// Renews value and then returns a boolean value indicating
    /// whether it should notify update.
    func renewValue(with store: RootAtomStore) -> Bool

    func notifyUnassigned(to observers: [AtomObserver])
}
