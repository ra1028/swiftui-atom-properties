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
        String(describing: Node.self) + (value.map { "(\($0))" } ?? "")
    }

    func reset(with store: StoreContext) {
        store.reset(atom)
    }
}

extension AtomCache: Equatable where Node: Equatable, Node.Loader.Value: Equatable {}
