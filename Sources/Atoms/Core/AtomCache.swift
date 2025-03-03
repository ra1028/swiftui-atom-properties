internal protocol AtomCacheProtocol {
    associatedtype Node: Atom

    var atom: Node { get }
    var value: Node.Produced { get }
}

internal struct AtomCache<Node: Atom>: AtomCacheProtocol, CustomStringConvertible {
    var atom: Node
    var value: Node.Produced

    var description: String {
        "\(value)"
    }
}
