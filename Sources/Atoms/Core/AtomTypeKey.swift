@usableFromInline
internal struct AtomTypeKey: Hashable, CustomStringConvertible {
    private let identifier: ObjectIdentifier
    private let getDescription: () -> String

    @usableFromInline
    var description: String {
        getDescription()
    }

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    @usableFromInline
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }

    @usableFromInline
    init<Node: Atom>(_: Node.Type) {
        identifier = ObjectIdentifier(Node.self)
        getDescription = {
            String(describing: Node.self)
        }
    }
}
