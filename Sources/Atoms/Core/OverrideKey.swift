@usableFromInline
internal struct OverrideKey: Hashable, Sendable {
    private let identifier: Identifier

    @usableFromInline
    init<Node: Atom>(_ atom: Node) {
        let key = UnsafeUncheckedSendable<AnyHashable>(atom.key)
        let type = ObjectIdentifier(Node.self)
        identifier = .node(key: key, type: type)
    }

    @usableFromInline
    init<Node: Atom>(_: Node.Type) {
        let type = ObjectIdentifier(Node.self)
        identifier = .type(type)
    }
}

private extension OverrideKey {
    enum Identifier: Hashable, Sendable {
        case node(key: UnsafeUncheckedSendable<AnyHashable>, type: ObjectIdentifier)
        case type(ObjectIdentifier)
    }
}
