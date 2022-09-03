/// A snapshot structure that captures specific set of values of atoms and their dependency graph.
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

    /// Restores the atom values that are captured in this snapshot.
    public func restore() {
        _restore()
    }

    /// Lookup a value associated with the given atom from the set captured in this snapshot..
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The captured value associated with the given atom if it exists.
    public func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom)
        let cache = atomCaches[key] as? AtomCache<Node>
        return cache?.value
    }
}
