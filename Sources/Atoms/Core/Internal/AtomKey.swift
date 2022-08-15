@usableFromInline
internal struct AtomKey: Hashable, CustomStringConvertible {
    @usableFromInline
    let typeKey: AtomTypeKey

    private let instance: AnyHashable
    private let getDescription: () -> String

    @usableFromInline
    var description: String {
        getDescription()
    }

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        hasher.combine(typeKey)
        hasher.combine(instance)
    }

    @usableFromInline
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.typeKey == rhs.typeKey && lhs.instance == rhs.instance
    }

    @usableFromInline
    init<Node: Atom>(_ atom: Node) {
        typeKey = AtomTypeKey(Node.self)
        instance = AnyHashable(atom.key)
        getDescription = {
            "\(String(describing: Node.self)) - key: \(atom.key)"
        }
    }
}
