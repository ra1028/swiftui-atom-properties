/// A protocol that abstracts restorable change history of an atom.
///
/// This type would be useful, for example, when you want to erase the type of
/// a ``Snapshot`` to add it to single array.
@MainActor
public protocol AtomHistory: Sendable {
    /// Restores the change in this history.
    func restore()
}

/// A snapshot that contains the changed atom and its value.
///
/// - SeeAlso: ``AtomObserver``
public struct Snapshot<Node: Atom>: AtomHistory {
    /// The snapshot atom instance.
    public let atom: Node

    /// The snapshot value of the``atom``.
    public let value: Node.State.Value

    private let store: AtomStore

    internal init(atom: Node, value: Node.State.Value, store: AtomStore) {
        self.atom = atom
        self.value = value
        self.store = store
    }

    /// Restores the change in this snapshot.
    public func restore() {
        store.restore(snapshot: self)
    }
}
