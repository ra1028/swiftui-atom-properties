public final class ModifiedAtomState<Node: Atom, Modifier: AtomModifier>: AtomStateProtocol where Node.State.Value == Modifier.Value {
    private var modified: Modifier.ModifiedValue?
    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

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

    public func override(context: Context, with modified: Modifier.ModifiedValue) {
        self.modified = modified
    }
}
