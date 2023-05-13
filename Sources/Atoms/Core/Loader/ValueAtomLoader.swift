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
    public func value(context: Context) -> Value {
        context.transaction(atom.value)
    }

    /// Associates given value and handle updates and cancellations.
    public func associateOverridden(value: Value, context: Context) -> Value {
        value
    }
}
