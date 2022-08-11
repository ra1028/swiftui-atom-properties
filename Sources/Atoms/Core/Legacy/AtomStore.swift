@usableFromInline
internal protocol AtomStore {
    @MainActor
    var container: StoreContainer? { get }

    @MainActor
    var overrides: Overrides? { get }

    @MainActor
    var observers: [AtomObserver] { get }

    @MainActor
    func read<Node: Atom>(_ atom: Node) -> Node.State.Value

    @MainActor
    func set<Node: StateAtom>(_ value: Node.Value, for atom: Node)

    @MainActor
    func refresh<Node: Atom>(_ atom: Node) async -> Node.State.Value where Node.State: RefreshableAtomState

    @MainActor
    func reset<Node: Atom>(_ atom: Node)

    @MainActor
    func watch<Node: Atom>(
        _ atom: Node,
        relationship: Relationship,
        shouldNotifyAfterUpdates: Bool,
        notifyUpdate: @MainActor @escaping () -> Void
    ) -> Node.State.Value

    @MainActor
    func watch<Node: Atom, Caller: Atom>(
        _ atom: Node,
        belongTo caller: Caller,
        shouldNotifyAfterUpdates: Bool
    ) -> Node.State.Value

    @MainActor
    func notifyUpdate<Node: Atom>(_ atom: Node)

    @MainActor
    func addTermination<Node: Atom>(_ atom: Node, termination: @MainActor @escaping () -> Void)
}
