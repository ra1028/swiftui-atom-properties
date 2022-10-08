@MainActor
internal protocol AtomCacheBase {
    var shouldKeepAlive: Bool { get }

    func reset(with store: StoreContext)
}

internal struct AtomCache<Node: Atom>: AtomCacheBase, CustomStringConvertible {
    var atom: Node
    var value: Node.Loader.Value?

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    var description: String {
        value.map { "\($0)" } ?? "nil"
    }

    func reset(with store: StoreContext) {
        store.reset(atom)
    }
}
