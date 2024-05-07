@usableFromInline
internal protocol OverrideProtocol {
    associatedtype Node: Atom

    var isScoped: Bool { get }
    var getValue: (Node) -> Node.Produced { get }
}

@usableFromInline
internal struct Override<Node: Atom>: OverrideProtocol {
    @usableFromInline
    let isScoped: Bool
    @usableFromInline
    let getValue: (Node) -> Node.Produced

    @usableFromInline
    init(isScoped: Bool, getValue: @escaping (Node) -> Node.Produced) {
        self.isScoped = isScoped
        self.getValue = getValue
    }
}
