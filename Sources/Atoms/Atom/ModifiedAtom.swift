/// An atom type that applies a modifier to an atom.
///
/// Use ``Atom/modifier(_:)`` instead of using this atom directly.
public struct ModifiedAtom<Node: Atom, Modifier: AtomModifier>: Atom where Node.Loader.Value == Modifier.BaseValue {
    /// A type representing the stable identity of this atom.
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

    /// A unique value used to identify the atom internally.
    public var key: Key {
        Key(atomKey: atom.key, modifierKey: modifier.key)
    }

    /// A loader that represents an actual implementation of this atom.
    public var _loader: ModifiedAtomLoader<Node, Modifier> {
        Loader(atom: atom, modifier: modifier)
    }
}
