/// An atom type that applies a modifier to an atom.
///
/// Use ``Atom/modifier(_:)`` instead of using this atom directly.
public struct ModifiedAtom<Node: Atom, Modifier: AtomModifier>: Atom where Node.Produced == Modifier.BaseValue {
    public typealias Produced = Modifier.Value

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
        AtomProducer { context in
            let value = context.transaction { $0.watch(atom) }
            return modifier.modify(value: value, context: context.modifierContext)
        } manageValue: { value, context in
            modifier.manageOverridden(value: value, context: context.modifierContext)
        } shouldUpdate: { oldValue, newValue in
            modifier.shouldUpdateTransitively(newValue: newValue, oldValue: oldValue)
        } performUpdate: { update in
            modifier.performTransitiveUpdate(update)
        }
    }
}

extension ModifiedAtom: AsyncAtom where Node: AsyncAtom, Modifier: RefreshableAtomModifier {
    public var refreshProducer: AtomRefreshProducer<Produced, Coordinator> {
        AtomRefreshProducer { context in
            let value = await context.transaction { context in
                await context.refresh(atom)
                return context.watch(atom)
            }

            return await modifier.refresh(modifying: value, context: context.modifierContext)
        } refreshValue: { value, context in
            await modifier.refresh(overridden: value, context: context.modifierContext)
        }
    }
}
