@MainActor
internal struct StoreState {
    var atomCaches = [AtomKey: AtomCacheBase]()
    var atomStates = [AtomKey: AtomStateBase]()

    nonisolated init() {}
}
