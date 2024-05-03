public protocol AsyncAtom: Atom {
    var refreshProducer: AtomRefreshProducer<Produced, Coordinator> { get }
}
