@usableFromInline
internal protocol StoreEntry {
    var host: AtomHostBase? { get }
}

internal struct WeakStoreEntry: StoreEntry {
    weak var host: AtomHostBase?
}

internal struct KeepAliveStoreEntry: StoreEntry {
    let host: AtomHostBase?
}
