@MainActor
internal final class NewStore {
    var graph = Graph()
    var state = StoreState()
}

struct StoreInteractor {
    private weak var store: NewStore?

    init(store: NewStore) {
        self.store = store
    }
}
