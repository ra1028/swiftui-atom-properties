@MainActor
internal protocol AtomCacheProtocol {
    associatedtype Node: Atom

    var atom: Node { get set }
    var value: Node.Loader.Value { get set }
}

internal struct AtomCache<Node: Atom>: AtomCacheProtocol, CustomStringConvertible {
    var atom: Node
    var value: Node.Loader.Value

    var description: String {
        "\(value)"
    }
}
