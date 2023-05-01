@MainActor
internal protocol AtomCacheProtocol: CustomStringConvertible {
    associatedtype Node: Atom

    var atom: Node { get set }
    var value: Node.Loader.Value? { get set }
    var shouldKeepAlive: Bool { get }

    func reset(with store: StoreContext)
}

internal extension AtomCacheProtocol {
    var description: String {
        value.map { "\($0)" } ?? "nil"
    }
}

internal struct AtomCache<Node: Atom>: AtomCacheProtocol {
    var atom: Node
    var value: Node.Loader.Value?

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    func reset(with store: StoreContext) {
        store.reset(atom)
    }
}
