public protocol AsyncAtomModifier: AtomModifier {
    func refreshProducer(atom: some AsyncAtom<Base>) -> AtomRefreshProducer<Produced, Coordinator>
}
