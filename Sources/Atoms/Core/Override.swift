@usableFromInline
internal protocol OverrideProtocol: Sendable {
    associatedtype Node: Atom

    var getValue: @MainActor (Node) -> Node.Produced { get }
}

@usableFromInline
internal struct Override<Node: Atom>: OverrideProtocol {
    @usableFromInline
    let getValue: @MainActor (Node) -> Node.Produced

    @usableFromInline
    init(getValue: @MainActor @escaping (Node) -> Node.Produced) {
        self.getValue = getValue
    }
}
