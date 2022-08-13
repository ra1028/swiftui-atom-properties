@usableFromInline
@MainActor
internal protocol AtomStore {
    func read<Node: Atom>(_ atom: Node) -> Node.State.Value

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node)

    func watch<Node: Atom, Dependent: Atom>(_ atom: Node, dependent: Dependent) -> Node.State.Value

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.State.Value

    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomValue

    func reset<Node: Atom>(_ atom: Node)

    func relay(observers: [AtomObserver]) -> AtomStore
}