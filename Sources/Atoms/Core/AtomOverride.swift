@MainActor
internal protocol AtomOverrideProtocol {
    associatedtype Node: Atom

    var value: (Node) -> Node.Loader.Value { get }
}

internal struct AtomOverride<Node: Atom>: AtomOverrideProtocol {
    let value: (Node) -> Node.Loader.Value
}
