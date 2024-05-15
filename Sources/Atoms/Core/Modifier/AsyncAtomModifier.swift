/// A modifier that you apply to an atom, producing a new refreshable value modified from the original value.
public protocol AsyncAtomModifier: AtomModifier {
    /// A producer that produces the refreshable value of this atom.
    func refreshProducer(atom: some AsyncAtom<Base>) -> AtomRefreshProducer<Produced>
}
