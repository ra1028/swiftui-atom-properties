@MainActor
public struct Snapshot {
    private let graph: Graph
    private let atomCaches: [AtomKey: AtomCacheBase]
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
}
