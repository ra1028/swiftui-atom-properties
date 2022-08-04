/// Internal use, a context structure that to interact with internal store.
@MainActor
public struct AtomHookContext<Coordinator> {
    @usableFromInline
    internal let _box: _AnyAtomHookContextBox

    @usableFromInline
    internal let coordinator: Coordinator

    internal init<Node: Atom>(
        atom: Node,
        coordinator: Coordinator,
        store: AtomStore
    ) {
        self._box = _AtomHookContextBox(atom: atom, store: store)
        self.coordinator = coordinator
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
internal protocol _AnyAtomHookContextBox {
    var atomContext: AtomRelationContext { get }

    func notifyUpdate()
    func addTermination(_ termination: @MainActor @escaping () -> Void)
}

@usableFromInline
internal struct _AtomHookContextBox<Node: Atom>: _AnyAtomHookContextBox {
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
