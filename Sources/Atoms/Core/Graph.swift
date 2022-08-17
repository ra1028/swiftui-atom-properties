@MainActor
internal struct Graph {
    /// Upstream atom keys.
    var dependencies = [AtomKey: Set<AtomKey>]()

    /// Downstream atom keys.
    var children = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}

    mutating func addEdge(for key: AtomKey, to child: AtomKey) {
        children[key, default: []].insert(child)
        dependencies[child, default: []].insert(key)
    }
}
