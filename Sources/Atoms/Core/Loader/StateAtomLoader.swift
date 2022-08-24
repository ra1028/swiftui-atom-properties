/// A loader protocol that represents an actual implementation of `StateAtom`.
public struct StateAtomLoader<Node: StateAtom>: AtomLoader {
    /// A type of value to provide.
    public typealias Value = Node.Value

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        context.transaction(atom.defaultValue)
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with value: Value) -> Value {
        value
    }
}
