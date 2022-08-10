/// An atom type that applies a modifier to an atom.
///
/// Use ``Atom/modifier(_:)`` instead of using this atom directly.
public struct ModifiedAtom<Node: Atom, Modifier: AtomModifier>: Atom where Node.State.Value == Modifier.Value {
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

    /// Creates a new state that is an actual implementation of this atom.
    ///
    /// - Returns: A state object that handles internal process and a value.
    public func makeState() -> ModifiedAtomState<Node, Modifier> {
        State(atom: atom, modifier: modifier)
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldNotifyUpdate(newValue: Modifier.ModifiedValue, oldValue: Modifier.ModifiedValue) -> Bool {
        modifier.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)
    }
}
