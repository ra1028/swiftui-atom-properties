@usableFromInline
@MainActor
internal protocol AtomStore {
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value

    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node)

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value

    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader

    func reset<Node: Atom>(_ atom: Node)

    func relay(observers: [AtomObserver]) -> AtomStore
}
