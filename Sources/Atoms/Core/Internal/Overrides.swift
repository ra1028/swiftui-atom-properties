@usableFromInline
@MainActor
internal struct Overrides {
    @usableFromInline
    internal var _entriesForNode = [AtomKey: _Override]()

    @usableFromInline
    internal var _entriesForType = [AtomTypeKey: _Override]()

    @inlinable
    mutating func insert<Node: Atom>(
        _ atom: Node,
        with value: @escaping (Node) -> Node.State.Value
    ) {
        let key = AtomKey(atom)
        _entriesForNode[key] = _ConcreteOverride(value)
    }

    @inlinable
    mutating func insert<Node: Atom>(
        _ atomType: Node.Type,
        with value: @escaping (Node) -> Node.State.Value
    ) {
        let key = AtomTypeKey(atomType)
        _entriesForType[key] = _ConcreteOverride(value)
    }

    @inlinable
    func value<Node: Atom>(for atom: Node) -> Node.State.Value? {
        let baseOverride = _entriesForNode[AtomKey(atom)] ?? _entriesForType[AtomTypeKey(Node.self)]

        guard let baseOverride = baseOverride else {
            return nil
        }

        guard let override = baseOverride as? _ConcreteOverride<Node> else {
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
internal protocol _Override {}

@usableFromInline
internal struct _ConcreteOverride<Node: Atom>: _Override {
    private let value: (Node) -> Node.State.Value

    @usableFromInline
    init(_ value: @escaping (Node) -> Node.State.Value) {
        self.value = value
    }

    @usableFromInline
    func value(for atom: Node) -> Node.State.Value {
        value(atom)
    }
}
