public struct ModifiedAtomValue<Node: Atom, Modifier: AtomModifier>: AtomValue where Node.State.Value == Modifier.Value {
    public typealias Value = Modifier.ModifiedValue

    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    public func get(context: Context) -> Value {
        let value = context.atomContext.watch(atom)
        return modifier.value(context: context, with: value)
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldNotifyUpdate(newValue: Modifier.ModifiedValue, oldValue: Modifier.ModifiedValue) -> Bool {
        modifier.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)
    }
}
