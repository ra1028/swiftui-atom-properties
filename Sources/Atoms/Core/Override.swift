@usableFromInline
internal protocol OverrideProtocol: Sendable {
    associatedtype Node: Atom

    var isScoped: Bool { get }
    var getValue: @MainActor @Sendable (Node) -> Node.Produced { get }
}

@usableFromInline
internal struct Override<Node: Atom>: OverrideProtocol {
    @usableFromInline
    let isScoped: Bool
    @usableFromInline
    let getValue: @MainActor @Sendable (Node) -> Node.Produced

    @usableFromInline
    init(isScoped: Bool, getValue: @escaping @MainActor @Sendable (Node) -> Node.Produced) {
        self.isScoped = isScoped
        self.getValue = getValue
    }
}
