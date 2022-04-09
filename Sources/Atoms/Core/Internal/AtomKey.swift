@usableFromInline
internal struct AtomKey: Hashable {
    private let typeIdentifier: ObjectIdentifier
    private let instance: AnyHashable

    init<Node: Atom>(_ atom: Node) {
        typeIdentifier = ObjectIdentifier(Node.self)
        instance = AnyHashable(atom.key)
    }

    init<Node: Atom>(_: Node.Type) {
        typeIdentifier = ObjectIdentifier(Node.self)
        instance = AnyHashable(typeIdentifier)
    }
}
