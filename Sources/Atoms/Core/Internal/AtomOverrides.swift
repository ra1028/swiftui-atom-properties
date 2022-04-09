@usableFromInline
@MainActor
internal struct AtomOverrides {
    private var entries = [AtomKey: Override]()

    mutating func insert<Node: Atom>(
        _ atom: Node,
        with value: @escaping (Node) -> Node.Hook.Value
    ) {
        let key = AtomKey(atom)
        entries[key] = OverrideValue(value)
    }

    mutating func insert<Node: Atom>(
        _ atomType: Node.Type,
        with value: @escaping (Node) -> Node.Hook.Value
    ) {
        let key = AtomKey(atomType)
        entries[key] = OverrideValue(value)
    }

    subscript<Node: Atom>(atom: Node) -> Node.Hook.Value? {
        // Individual atom override takes precedence.
        let override = entries[AtomKey(atom)] ?? entries[AtomKey(Node.self)]
        return override?.value(of: atom)
    }
}

@MainActor
private protocol Override {}

private extension Override {
    func value<Node: Atom>(of atom: Node) -> Node.Hook.Value {
        guard let value = self as? OverrideValue<Node> else {
            fatalError(
                """
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: self))
                Expected: OverrideValue<\(Node.self)>
                """
            )
        }

        return value(of: atom)
    }
}

private struct OverrideValue<Node: Atom>: Override {
    private let value: (Node) -> Node.Hook.Value

    init(_ value: @escaping (Node) -> Node.Hook.Value) {
        self.value = value
    }

    func callAsFunction(of atom: Node) -> Node.Hook.Value {
        value(atom)
    }
}
