/// An object that stores the state of atoms and its dependency graph.
@MainActor
public final class AtomStore {
    internal var graph = Graph()
    internal var state = StoreState()

    /// Creates a new store.
    nonisolated public init() {}
}
