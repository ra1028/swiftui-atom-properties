@MainActor
internal struct Graph {
    /// Upstream atom keys.
    private var dependencies = [AtomKey: Set<AtomKey>]()

    /// Downstream atom keys.
    private var children = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}

    func hasChildren(for key: AtomKey) -> Bool {
        children[key].map { !$0.isEmpty } ?? false
    }

    func dependencies(for key: AtomKey) -> Set<AtomKey> {
        dependencies[key] ?? []
    }

    func children(for key: AtomKey) -> Set<AtomKey> {
        children[key] ?? []
    }

    mutating func addEdge(for key: AtomKey, to child: AtomKey) {
        children[key, default: []].insert(child)
        dependencies[child, default: []].insert(key)
    }

    mutating func remove(child: AtomKey, for key: AtomKey) {
        children[key]?.remove(child)
    }

    @discardableResult
    mutating func removeDependencies(for key: AtomKey) -> Set<AtomKey> {
        dependencies.removeValue(forKey: key) ?? []
    }

    @discardableResult
    mutating func removeChildren(for key: AtomKey) -> Set<AtomKey> {
        children.removeValue(forKey: key) ?? []
    }
}
