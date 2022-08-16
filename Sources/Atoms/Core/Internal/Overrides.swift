@usableFromInline
@MainActor
internal struct Overrides {
    @usableFromInline
    internal var _entriesForNode = [AtomKey: Override]()

    @usableFromInline
    internal var _entriesForType = [AtomTypeKey: Override]()

    mutating func insert<Node: Atom>(
        _ atom: Node,
        with value: @escaping (Node) -> Node.Loader.Value
    ) {
        let key = AtomKey(atom)
        _entriesForNode[key] = ConcreteOverride(value)
    }

    mutating func insert<Node: Atom>(
        _ atomType: Node.Type,
        with value: @escaping (Node) -> Node.Loader.Value
    ) {
        let key = AtomTypeKey(atomType)
        _entriesForType[key] = ConcreteOverride(value)
    }

    func value<Node: Atom>(for atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom)
        let baseOverride = _entriesForNode[key] ?? _entriesForType[key.typeKey]

        guard let baseOverride = baseOverride else {
            return nil
        }

        guard let override = baseOverride as? ConcreteOverride<Node> else {
            assertionFailure(
                """
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: self))
                Expected: OverrideValue<\(Node.self)>
                """
            )

            return nil
        }

        return override.value(for: atom)
    }
}

@usableFromInline
@MainActor
internal protocol Override {}

@usableFromInline
internal struct ConcreteOverride<Node: Atom>: Override {
    private let value: (Node) -> Node.Loader.Value

    @usableFromInline
    init(_ value: @escaping (Node) -> Node.Loader.Value) {
        self.value = value
    }

    @usableFromInline
    func value(for atom: Node) -> Node.Loader.Value {
        value(atom)
    }
}
