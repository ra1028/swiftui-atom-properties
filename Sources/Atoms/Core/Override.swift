@usableFromInline
internal protocol OverrideProtocol {
    associatedtype Node: Atom

    var isScoped: Bool { get }
    var value: (Node) -> Node.Produced { get }
}

@usableFromInline
internal struct Override<Node: Atom>: OverrideProtocol {
    @usableFromInline
    let isScoped: Bool
    @usableFromInline
    let value: (Node) -> Node.Produced

    @usableFromInline
    init(isScoped: Bool, value: @escaping (Node) -> Node.Produced) {
        self.isScoped = isScoped
        self.value = value
    }
}
