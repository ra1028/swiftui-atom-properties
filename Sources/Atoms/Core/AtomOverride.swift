@usableFromInline
internal protocol AtomOverrideProtocol {
    associatedtype Node: Atom

    var value: (Node) -> Node.Loader.Value { get }
}

@usableFromInline
internal struct AtomOverride<Node: Atom>: AtomOverrideProtocol {
    @usableFromInline
    let value: (Node) -> Node.Loader.Value

    @usableFromInline
    init(value: @escaping (Node) -> Node.Loader.Value) {
        self.value = value
    }
}
