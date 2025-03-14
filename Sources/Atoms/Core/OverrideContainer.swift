@usableFromInline
internal struct OverrideContainer {
    private struct Entry {
        var typeOverride: (any OverrideProtocol)?
        var instanceOverrides = [InstanceKey: any OverrideProtocol]()
    }

    private var entries = [TypeKey: Entry]()

    @usableFromInline
    mutating func addOverride<Node: Atom>(for atom: Node, with value: @MainActor @escaping (Node) -> Node.Produced) {
        let typeKey = TypeKey(Node.self)
        let instanceKey = InstanceKey(atom)
        entries[typeKey, default: Entry()].instanceOverrides[instanceKey] = Override(getValue: value)
    }

    @usableFromInline
    mutating func addOverride<Node: Atom>(for atomType: Node.Type, with value: @MainActor @escaping (Node) -> Node.Produced) {
        let typeKey = TypeKey(atomType)
        entries[typeKey, default: Entry()].typeOverride = Override(getValue: value)
    }

    func getOverride<Node: Atom>(for atom: Node) -> Override<Node>? {
        let typeKey = TypeKey(Node.self)

        guard let entry = entries[typeKey] else {
            return nil
        }

        let instanceKey = InstanceKey(atom)
        let baseOverride = entry.instanceOverrides[instanceKey] ?? entry.typeOverride

        guard let baseOverride else {
            return nil
        }

        guard let override = baseOverride as? Override<Node> else {
            assertionFailure(
                """
                [Atoms]
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: baseOverride))
                Expected: Override<\(Node.self)>
                """
            )

            return nil
        }

        return override
    }
}

private extension OverrideContainer {
    struct TypeKey: Hashable, Sendable {
        private let identifier: ObjectIdentifier

        init<Node: Atom>(_: Node.Type) {
            identifier = ObjectIdentifier(Node.self)
        }
    }

    struct InstanceKey: Hashable, Sendable {
        private let key: UnsafeUncheckedSendable<AnyHashable>

        init<Node: Atom>(_ atom: Node) {
            key = UnsafeUncheckedSendable(atom.key)
        }
    }
}
