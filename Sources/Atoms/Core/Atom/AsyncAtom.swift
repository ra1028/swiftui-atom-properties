public protocol AsyncAtom<Produced>: Atom {
    var refreshProducer: AtomRefreshProducer<Produced, Coordinator> { get }
}
