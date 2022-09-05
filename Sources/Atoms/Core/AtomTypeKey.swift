internal struct AtomTypeKey: Hashable, CustomStringConvertible {
    private let identifier: ObjectIdentifier
    private let getName: () -> String

    init<Node: Atom>(_: Node.Type) {
        identifier = ObjectIdentifier(Node.self)
        getName = { String(describing: Node.self) }
    }

    var description: String {
        getName()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
