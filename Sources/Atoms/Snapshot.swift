/// A snapshot structure that captures specific set of values of atoms and their dependency graph.
public struct Snapshot: CustomStringConvertible {
    internal let graph: Graph
    internal let caches: [AtomKey: AtomCacheBase]
    private let _restore: @MainActor () -> Void

    internal init(
        graph: Graph,
        caches: [AtomKey: AtomCacheBase],
        restore: @MainActor @escaping () -> Void
    ) {
        self.graph = graph
        self.caches = caches
        self._restore = restore
    }

    /// A textual representation of this snapshot.
    public var description: String {
        """
        Snapshot
        - graph: \(graph)
        - caches: \(caches)
        """
    }

    /// Restores the atom values that are captured in this snapshot.
    @MainActor
    public func restore() {
        _restore()
    }

    /// Lookup a value associated with the given atom from the set captured in this snapshot..
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The captured value associated with the given atom if it exists.
    @MainActor
    public func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom)
        let cache = caches[key] as? AtomCache<Node>
        return cache?.value
    }
}
