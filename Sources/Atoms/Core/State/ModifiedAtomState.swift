/// A state that is actual implementation of `ModifiedAtom`.
public final class ModifiedAtomState<Node: Atom, Modifier: AtomModifier>: AtomState where Node.State.Value == Modifier.Value {
    private var modifiedValue: Modifier.ModifiedValue?
    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> Modifier.ModifiedValue {
        if let modifiedValue = modifiedValue {
            return modifiedValue
        }

        let value = context.atomContext.watch(atom)
        let modifiedValue = modifier.value(context: context, with: value) { [weak self] modifiedValue in
            self?.modifiedValue = modifiedValue
        }
        self.modifiedValue = modifiedValue

        return modifiedValue
    }

    /// Overrides the value with an arbitrary value.
    public func override(with modifiedValue: Modifier.ModifiedValue, context: Context) {
        self.modifiedValue = modifiedValue
    }
}
