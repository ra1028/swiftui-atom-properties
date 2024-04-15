internal struct AtomKey: Hashable {
    private let key: AnyHashable
    private let type: ObjectIdentifier
    private let scopeKey: ScopeKey?
    private let anyAtomType: Any.Type

    var debugLabel: String {
        let atomLabel = String(describing: anyAtomType)

        if let scopeKey {
            return atomLabel + "-scoped:\(scopeKey.debugLabel)"
        }
        else {
            return atomLabel
        }
    }

    var isScoped: Bool {
        scopeKey != nil
    }

    init<Node: Atom>(_ atom: Node, scopeKey: ScopeKey?) {
        self.key = AnyHashable(atom.key)
        self.type = ObjectIdentifier(Node.self)
        self.scopeKey = scopeKey
        self.anyAtomType = Node.self
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(type)
        hasher.combine(scopeKey)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.type == rhs.type && lhs.scopeKey == rhs.scopeKey
    }
}
