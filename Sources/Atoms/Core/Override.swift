@usableFromInline
internal protocol OverrideProtocol: Sendable {
    associatedtype Node: Atom

    var getValue: @MainActor @Sendable (Node) -> Node.Produced { get }
}

@usableFromInline
internal struct Override<Node: Atom>: OverrideProtocol {
    @usableFromInline
    let getValue: @MainActor @Sendable (Node) -> Node.Produced

    @usableFromInline
    init(getValue: @escaping @MainActor @Sendable (Node) -> Node.Produced) {
        self.getValue = getValue
    }
}
