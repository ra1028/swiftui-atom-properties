@MainActor
internal protocol AtomOverrideProtocol {
    associatedtype Node: Atom

    var scopeKey: ScopeKey { get }
    var value: (Node) -> Node.Loader.Value { get }
}

internal struct AtomOverride<Node: Atom>: AtomOverrideProtocol {
    let scopeKey: ScopeKey
    let value: (Node) -> Node.Loader.Value
}
