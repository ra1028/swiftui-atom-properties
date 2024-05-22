/// An atom type that applies a modifier to an atom.
///
/// Use ``Atom/modifier(_:)`` instead of using this atom directly.
public struct ModifiedAtom<Node: Atom, Modifier: AtomModifier>: Atom where Node.Produced == Modifier.Base {
    /// The type of value that this atom produces.
    public typealias Produced = Modifier.Produced

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

    /// A unique value used to identify the atom.
    public var key: Key {
        Key(atomKey: atom.key, modifierKey: modifier.key)
    }

    /// A producer that produces the value of this atom.
    public var producer: AtomProducer<Produced> {
        modifier.producer(atom: atom)
    }
}

extension ModifiedAtom: AsyncAtom where Node: AsyncAtom, Modifier: AsyncAtomModifier {
    /// A producer that produces the refreshable value of this atom.
    public var refreshProducer: AtomRefreshProducer<Produced> {
        modifier.refreshProducer(atom: atom)
    }
}

extension ModifiedAtom: Scoped where Node: Scoped {
    /// A scope ID which is to find a matching scope.
    public var scopeID: Node.ScopeID {
        atom.scopeID
    }
}
