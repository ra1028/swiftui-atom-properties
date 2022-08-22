@MainActor
internal struct Graph {
    var dependencies = [AtomKey: Set<AtomKey>]()
    var children = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}
}
