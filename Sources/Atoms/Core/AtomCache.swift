@MainActor
internal protocol AtomCacheProtocol: CustomStringConvertible {
    associatedtype Node: Atom

    var atom: Node { get set }
    var value: Node.Loader.Value { get set }
}

internal extension AtomCacheProtocol {
    var description: String {
        "\(value)"
    }
}

internal struct AtomCache<Node: Atom>: AtomCacheProtocol {
    var atom: Node
    var value: Node.Loader.Value
}
