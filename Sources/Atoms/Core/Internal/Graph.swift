@MainActor
internal struct Graph {
    /// Downstream atom keys.
    var dependents = [AtomKey: Set<AtomKey>]()

    /// Upstream atom keys.
    var dependencies = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}
}
