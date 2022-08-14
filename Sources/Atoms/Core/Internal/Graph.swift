@MainActor
internal struct Graph {
    /// Upstream atom keys.
    var dependencies = [AtomKey: Set<AtomKey>]()

    /// Downstream atom keys.
    var children = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}
}
