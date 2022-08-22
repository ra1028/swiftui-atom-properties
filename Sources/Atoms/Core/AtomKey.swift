internal struct AtomKey: Hashable {
    let typeKey: AtomTypeKey

    private let identifier: AnyHashable

    init<Node: Atom>(_ atom: Node) {
        typeKey = AtomTypeKey(Node.self)
        identifier = AnyHashable(atom.key)
    }
}
