internal struct AtomKey: Hashable {
    private let key: AnyHashable
    private let type: ObjectIdentifier
    private let getName: () -> String

    var name: String {
        getName()
    }

    init<Node: Atom>(_ atom: Node) {
        key = AnyHashable(atom.key)
        type = ObjectIdentifier(Node.self)
        getName = { String(describing: Node.self) }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(type)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.type == rhs.type
    }
}
