@usableFromInline
internal struct AtomTypeKey: Hashable {
    private let typeIdentifier: ObjectIdentifier

    @usableFromInline
    init<Node: Atom>(_: Node.Type) {
        typeIdentifier = ObjectIdentifier(Node.self)
    }
}
