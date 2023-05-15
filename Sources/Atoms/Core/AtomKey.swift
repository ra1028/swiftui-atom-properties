internal struct AtomKey: Hashable, CustomStringConvertible {
    private let key: AnyHashable
    private let type: ObjectIdentifier
    private let overrideScopeKey: ScopeKey?
    private let getName: () -> String

    var description: String {
        if let overrideScopeKey {
            let name = getName()
            let id = String(overrideScopeKey.hashValue, radix: 36, uppercase: false)
            return name + "-override:\(id)"
        }
        else {
            return getName()
        }
    }

    init<Node: Atom>(_ atom: Node, overrideScopeKey: ScopeKey?) {
        self.key = AnyHashable(atom.key)
        self.type = ObjectIdentifier(Node.self)
        self.overrideScopeKey = overrideScopeKey
        self.getName = { String(describing: Node.self) }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(type)
        hasher.combine(overrideScopeKey)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.type == rhs.type && lhs.overrideScopeKey == rhs.overrideScopeKey
    }
}
