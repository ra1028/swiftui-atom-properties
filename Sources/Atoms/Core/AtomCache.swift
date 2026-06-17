internal protocol AtomCacheProtocol {
    associatedtype Node: Atom

    var atom: Node { get }
    var value: Node.Produced { get }
    var rootScopeValues: ScopeValues { get }
    var scopeValues: ScopeValues? { get }
    var shouldKeepAlive: Bool { get }

    func updated(value: Node.Produced) -> Self
}

internal struct AtomCache<Node: Atom>: AtomCacheProtocol, CustomStringConvertible {
    let atom: Node
    let value: Node.Produced
    let rootScopeValues: ScopeValues
    let scopeValues: ScopeValues?

    init(
        atom: Node,
        value: Node.Produced,
        rootScopeValues: ScopeValues,
        scopeValues: ScopeValues?
    ) {
        self.atom = atom
        self.value = value
        self.rootScopeValues = rootScopeValues
        self.scopeValues = scopeValues
    }

    var description: String {
        "\(value)"
    }

    var shouldKeepAlive: Bool {
        atom is any KeepAlive
    }

    func updated(value: Node.Produced) -> Self {
        AtomCache(atom: atom, value: value, rootScopeValues: rootScopeValues, scopeValues: scopeValues)
    }
}
