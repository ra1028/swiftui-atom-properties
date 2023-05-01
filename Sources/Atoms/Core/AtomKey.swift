@usableFromInline
internal struct AtomKey: Hashable, CustomStringConvertible {
    private let identifier: AnyHashable

    let typeKey: AtomTypeKey

    init<Node: Atom>(_ atom: Node) {
        typeKey = AtomTypeKey(Node.self)
        identifier = AnyHashable(atom.key)
    }

    @usableFromInline
    var description: String {
        typeKey.description
    }
}
