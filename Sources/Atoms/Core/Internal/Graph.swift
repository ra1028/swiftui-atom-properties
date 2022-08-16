@MainActor
internal struct Graph {
    /// Upstream atom keys.
    var dependencies = [AtomKey: Set<AtomKey>]()

    /// Downstream atom keys.
    var children = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}

    func hasChildren(for key: AtomKey) -> Bool {
        guard let children = children[key] else {
            return false
        }
        return !children.isEmpty
    }

    mutating func addEdge(for key: AtomKey, to child: AtomKey) {
        children[key, default: []].insert(child)
        dependencies[child, default: []].insert(key)
    }
}
