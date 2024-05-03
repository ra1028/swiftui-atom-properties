/// An atom type that applies a modifier to an atom.
///
/// Use ``Atom/modifier(_:)`` instead of using this atom directly.
public struct ModifiedAtom<Node: Atom, Modifier: AtomModifier>: Atom where Node.Produced == Modifier.Base {
    public typealias Produced = Modifier.Produced
    public typealias Coordinator = Modifier.Coordinator

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

    public var producer: AtomProducer<Produced, Coordinator> {
        modifier.producer(atom: atom)
    }

    public func makeCoordinator() -> Coordinator {
        modifier.makeCoordinator()
    }
}

extension ModifiedAtom: AsyncAtom where Node: AsyncAtom, Modifier: AsyncAtomModifier {
    public var refreshProducer: AtomRefreshProducer<Produced, Coordinator> {
        modifier.refreshProducer(atom: atom)
    }
}
