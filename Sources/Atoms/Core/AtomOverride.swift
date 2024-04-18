@usableFromInline
internal protocol AtomOverrideProtocol {
    associatedtype Node: Atom

    var isScoped: Bool { get }
    var value: (Node) -> Node.Loader.Value { get }
}

@usableFromInline
internal struct AtomOverride<Node: Atom>: AtomOverrideProtocol {
    @usableFromInline
    let isScoped: Bool
    @usableFromInline
    let value: (Node) -> Node.Loader.Value

    @usableFromInline
    init(isScoped: Bool, value: @escaping (Node) -> Node.Loader.Value) {
        self.isScoped = isScoped
        self.value = value
    }
}
