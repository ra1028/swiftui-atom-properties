/// A state that is actual implementation of `ModifiedAtom`.
public final class ModifiedAtomState<Node: Atom, Modifier: AtomModifier>: AtomState where Node.State.Value == Modifier.Value {
    private var modified: Modifier.ModifiedValue?
    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> Modifier.ModifiedValue {
        if let modified = modified {
            return modified
        }

        let value = context.atomContext.watch(atom)
        let modified = modifier.value(context: context, with: value) { [weak self] modified in
            self?.modified = modified
        }
        self.modified = modified

        return modified
    }

    /// Overrides the value with an arbitrary value.
    public func override(context: Context, with modified: Modifier.ModifiedValue) {
        self.modified = modified
    }
}
