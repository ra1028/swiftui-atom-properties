public struct ModifiedAtom<Node: Atom, Modifier: AtomModifier>: Atom where Node.Hook.Value == Modifier.Value {
    public struct Key: Hashable {
        private let atomKey: Node.Key
        private let modifierKey: Modifier.Key

        fileprivate init(
            atomKey: Node.Key,
            modifierKey: Modifier.Key
        ) {
            self.atomKey = atomKey
            self.modifierKey = modifierKey
        }
    }

    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    public var key: Key {
        Key(atomKey: atom.key, modifierKey: modifier.key)
    }

    public var hook: ModifiedHook<Node, Modifier> {
        ModifiedHook(atom: atom, modifier: modifier)
    }

    public func shouldNotifyUpdate(newValue: Modifier.ModifiedValue, oldValue: Modifier.ModifiedValue) -> Bool {
        modifier.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)
    }
}
