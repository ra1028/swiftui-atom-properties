/// A loader protocol that represents an actual implementation of `ValueAtom`.
public struct ValueAtomLoader<Node: ValueAtom>: AtomLoader {
    /// A type of value to provide.
    public typealias Value = Node.Value

    /// A type to coordinate with the atom.
    public typealias Coordinator = Node.Coordinator

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        context.transaction(atom.value)
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with value: Value) -> Value {
        value
    }
}
