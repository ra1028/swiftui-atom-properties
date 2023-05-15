internal struct OverrideKey: Hashable {
    private let identifier: Identifier

    init<Node: Atom>(_ atom: Node) {
        let key = AnyHashable(atom.key)
        let type = ObjectIdentifier(Node.self)
        identifier = .node(key: key, type: type)
    }

    init<Node: Atom>(_: Node.Type) {
        let type = ObjectIdentifier(Node.self)
        identifier = .type(type)
    }
}

private extension OverrideKey {
    enum Identifier: Hashable {
        case node(key: AnyHashable, type: ObjectIdentifier)
        case type(ObjectIdentifier)
    }
}
