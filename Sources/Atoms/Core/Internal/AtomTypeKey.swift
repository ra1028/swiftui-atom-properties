@usableFromInline
internal struct AtomTypeKey: Hashable, CustomStringConvertible {
    private let typeIdentifier: ObjectIdentifier
    private let getDescription: () -> String

    @usableFromInline
    var description: String {
        getDescription()
    }

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        hasher.combine(typeIdentifier)
    }

    @usableFromInline
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.typeIdentifier == rhs.typeIdentifier
    }

    @usableFromInline
    init<Node: Atom>(_: Node.Type) {
        typeIdentifier = ObjectIdentifier(Node.self)
        getDescription = {
            String(describing: Node.self)
        }
    }
}
