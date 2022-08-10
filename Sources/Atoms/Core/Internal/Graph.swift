internal struct Graph {
    /// Downstream atom keys.
    var nodes = [AtomKey: Set<AtomKey>]()

    /// Upstream atom keys.
    var dependencies = [AtomKey: Set<AtomKey>]()
}
