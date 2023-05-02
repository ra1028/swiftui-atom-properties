@usableFromInline
internal struct Overrides {
    private var entriesForNode = [AtomKey: any AtomOverrideProtocol]()
    private var entriesForType = [AtomTypeKey: any AtomOverrideProtocol]()

    nonisolated init() {}

    mutating func insert<Node: Atom>(
        _ atom: Node,
        with value: @escaping (Node) -> Node.Loader.Value
    ) {
        let key = AtomKey(atom)
        entriesForNode[key] = AtomOverride(value: value)
    }

    mutating func insert<Node: Atom>(
        _ atomType: Node.Type,
        with value: @escaping (Node) -> Node.Loader.Value
    ) {
        let key = AtomTypeKey(atomType)
        entriesForType[key] = AtomOverride(value: value)
    }

    func hasValue<Node: Atom>(for atom: Node) -> Bool {
        let key = AtomKey(atom)
        return entriesForNode[key] != nil || entriesForType[key.typeKey] != nil
    }

    func value<Node: Atom>(for atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom)
        let baseOverride = entriesForNode[key] ?? entriesForType[key.typeKey]

        guard let baseOverride else {
            return nil
        }

        guard let override = baseOverride as? AtomOverride<Node> else {
            assertionFailure(
                """
                [Atoms]
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: self))
                Expected: AtomOverride<\(Node.self)>
                """
            )

            return nil
        }

        return override.value(atom)
    }
}

@MainActor
internal protocol AtomOverrideProtocol {
    associatedtype Node: Atom

    var value: (Node) -> Node.Loader.Value { get }
}

internal struct AtomOverride<Node: Atom>: AtomOverrideProtocol {
    let value: (Node) -> Node.Loader.Value
}
