@usableFromInline
internal struct AtomKey: Hashable {
    @usableFromInline
    let typeKey: AtomTypeKey

    private let instance: AnyHashable

    @usableFromInline
    init<Node: Atom>(_ atom: Node) {
        typeKey = AtomTypeKey(Node.self)
        instance = AnyHashable(atom.key)
    }
}
