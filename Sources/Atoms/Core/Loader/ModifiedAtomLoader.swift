/// A loader protocol that represents an actual implementation of `ModifiedAtom`.
public struct ModifiedAtomLoader<Node: Atom, Modifier: AtomModifier>: AtomLoader where Node.Loader.Value == Modifier.Value {
    /// A type of value to provide.
    public typealias Value = Modifier.ModifiedValue

    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        let value = context.transaction { $0.watch(atom) }
        return modifier.value(context: context, with: value)
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with value: Modifier.ModifiedValue) -> Modifier.ModifiedValue {
        modifier.handle(context: context, with: value)
    }

    /// Returns a boolean value indicating whether it should notify updates to downstream
    /// by checking the equivalence of the given old value and new value.
    public func shouldNotifyUpdate(newValue: Modifier.ModifiedValue, oldValue: Modifier.ModifiedValue) -> Bool {
        modifier.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)
    }
}
