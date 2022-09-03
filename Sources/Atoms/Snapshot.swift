@MainActor
public struct Snapshot {
    internal let graph: Graph
    internal let atomCaches: [AtomKey: AtomCacheBase]
    private let _restore: @MainActor () -> Void

    internal init(
        graph: Graph,
        atomCaches: [AtomKey: AtomCacheBase],
        restore: @MainActor @escaping () -> Void
    ) {
        self.graph = graph
        self.atomCaches = atomCaches
        self._restore = restore
    }

    public func restore() {
        _restore()
    }

    public func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom)
        let cache = atomCaches[key] as? AtomCache<Node>
        return cache?.value
    }
}
