internal protocol AtomCacheProtocol {
    associatedtype Node: Atom

    var atom: Node { get }
    var value: Node.Produced { get }
    var initScopeKey: ScopeKey? { get }

    func updated(value: Node.Produced) -> Self
}

internal struct AtomCache<Node: Atom>: AtomCacheProtocol, CustomStringConvertible {
    let atom: Node
    let value: Node.Produced
    let initScopeKey: ScopeKey?

    var description: String {
        "\(value)"
    }

    func updated(value: Node.Produced) -> Self {
        AtomCache(atom: atom, value: value, initScopeKey: initScopeKey)
    }
}
