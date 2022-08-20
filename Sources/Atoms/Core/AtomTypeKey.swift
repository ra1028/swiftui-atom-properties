@usableFromInline
internal struct AtomTypeKey: Hashable {
    private let identifier: ObjectIdentifier

    @usableFromInline
    init<Node: Atom>(_: Node.Type) {
        identifier = ObjectIdentifier(Node.self)
    }
}
