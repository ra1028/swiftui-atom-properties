@usableFromInline
@MainActor
internal final class Store {
    var graph = Graph()
    var state = StoreState()

    nonisolated init() {}
}
