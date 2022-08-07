@usableFromInline
internal protocol AtomStore {
    @MainActor
    var container: StoreContainer? { get }

    @MainActor
    var overrides: AtomOverrides? { get }

    @MainActor
    var observers: [AtomObserver] { get }

    @MainActor
    func read<Node: Atom>(_ atom: Node) -> Node.Hook.Value

    @MainActor
    func set<Node: Atom>(_ value: Node.Hook.Value, for atom: Node) where Node.Hook: AtomStateHook

    @MainActor
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Hook.Value where Node.Hook: AtomRefreshableHook

    @MainActor
    func reset<Node: Atom>(_ atom: Node)

    @MainActor
    func watch<Node: Atom>(
        _ atom: Node,
        relationship: Relationship,
        shouldNotifyAfterUpdates: Bool,
        notifyUpdate: @MainActor @escaping () -> Void
    ) -> Node.Hook.Value

    @MainActor
    func watch<Node: Atom, Caller: Atom>(
        _ atom: Node,
        belongTo caller: Caller,
        shouldNotifyAfterUpdates: Bool
    ) -> Node.Hook.Value

    @MainActor
    func notifyUpdate<Node: Atom>(_ atom: Node)

    @MainActor
    func addTermination<Node: Atom>(_ atom: Node, termination: @MainActor @escaping () -> Void)

    @MainActor
    func restore<Node: Atom>(snapshot: Snapshot<Node>)
}
