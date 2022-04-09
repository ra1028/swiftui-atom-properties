@usableFromInline
@MainActor
internal struct Relationship {
    private weak var container: RelationshipContainer?

    init(container: RelationshipContainer) {
        self.container = container
    }

    subscript<Node: Atom>(_ atom: Node) -> Relation? {
        get {
            let key = AtomKey(atom)
            return container?.entries[key]
        }
        nonmutating set {
            let key = AtomKey(atom)
            container?.entries[key] = newValue
        }
    }
}
