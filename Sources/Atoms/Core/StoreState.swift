@MainActor
internal struct StoreState {
    var atomCaches = [AtomKey: AtomCache]()
    var atomStates = [AtomKey: AtomState]()

    nonisolated init() {}
}
