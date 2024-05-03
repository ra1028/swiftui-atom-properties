public protocol AsyncAtomModifier: AtomModifier {
    func refreshProducer<Node: AsyncAtom<Base>>(atom: Node) -> AtomRefreshProducer<Produced, Coordinator>
}
