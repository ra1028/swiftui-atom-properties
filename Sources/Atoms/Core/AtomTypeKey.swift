internal struct AtomTypeKey: Hashable {
    private let identifier: ObjectIdentifier

    init<Node: Atom>(_: Node.Type) {
        identifier = ObjectIdentifier(Node.self)
    }
}
