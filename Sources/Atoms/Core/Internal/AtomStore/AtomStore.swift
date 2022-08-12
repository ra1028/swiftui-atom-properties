@usableFromInline
@MainActor
internal protocol AtomStore {
    func read<Node: Atom>(_ atom: Node) -> Node.State.Value

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node)

    func watch<Node: Atom, Downstream: Atom>(_ atom: Node, downstream: Downstream) -> Node.State.Value

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.State.Value

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue

    func reset<Node: Atom>(_ atom: Node)

    func addTermination<Node: Atom>(for atom: Node, _ termination: @MainActor @escaping () -> Void)

    func relay(observers: [AtomObserver]) -> AtomStore
}
