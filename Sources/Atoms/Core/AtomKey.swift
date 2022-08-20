@usableFromInline
internal struct AtomKey: Hashable {
    @usableFromInline
    let typeKey: AtomTypeKey

    private let identifier: AnyHashable

    @usableFromInline
    init<Node: Atom>(_ atom: Node) {
        typeKey = AtomTypeKey(Node.self)
        identifier = AnyHashable(atom.key)
    }
}
