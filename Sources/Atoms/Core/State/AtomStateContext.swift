/// A type of the context structure that to interact with an atom store.
@MainActor
public struct AtomStateContext {
    @usableFromInline
    internal let _box: _AnyAtomStateContextBox

    internal init<Node: Atom>(atom: Node, store: AtomStore) {
        _box = _AtomStateContextBox(atom: atom, store: store)
    }

    @inlinable
    internal var atomContext: AtomRelationContext {
        _box.atomContext
    }

    @inlinable
    internal func notifyUpdate() {
        _box.notifyUpdate()
    }

    @inlinable
    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _box.addTermination(termination)
    }
}

@usableFromInline
@MainActor
internal protocol _AnyAtomStateContextBox {
    var atomContext: AtomRelationContext { get }

    func notifyUpdate()
    func addTermination(_ termination: @MainActor @escaping () -> Void)
}

@usableFromInline
internal struct _AtomStateContextBox<Node: Atom>: _AnyAtomStateContextBox {
    let atom: Node
    let store: AtomStore

    init(atom: Node, store: AtomStore) {
        self.atom = atom
        self.store = store
    }

    @usableFromInline
    var atomContext: AtomRelationContext {
        AtomRelationContext(atom: atom, store: store)
    }

    @usableFromInline
    func notifyUpdate() {
        store.notifyUpdate(atom)
    }

    @usableFromInline
    func addTermination(_ termination: @MainActor @escaping () -> Void) {
        store.addTermination(atom, termination: termination)
    }
}
