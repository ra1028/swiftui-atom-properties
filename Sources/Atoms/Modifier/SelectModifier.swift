public extension Atom {
    @MainActor
    func select<Value: Equatable>(
        _ keyPath: KeyPath<Hook.Value, Value>
    ) -> ModifiedAtom<SelectModifier<Self, Value>> {
        ModifiedAtom(modifier: SelectModifier(atom: self, keyPath: keyPath))
    }
}

public struct SelectModifier<Node: Atom, Value: Equatable>: AtomModifier {
    public struct Key: Hashable {
        private let atomKey: Node.Key
        private let keyPath: KeyPath<Node.Hook.Value, Value>

        fileprivate init(
            atomKey: Node.Key,
            keyPath: KeyPath<Node.Hook.Value, Value>
        ) {
            self.atomKey = atomKey
            self.keyPath = keyPath
        }
    }

    public final class Coordinator {
        internal var value: Value?
    }

    private let atom: Node
    private let keyPath: KeyPath<Node.Hook.Value, Value>

    internal init(atom: Node, keyPath: KeyPath<Node.Hook.Value, Value>) {
        self.atom = atom
        self.keyPath = keyPath
    }

    public var key: Key {
        Key(atomKey: atom.key, keyPath: keyPath)
    }

    public func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool {
        newValue != oldValue
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func value(context: Context) -> Value {
        context.coordinator.value ?? _assertingFallbackValue(context: context)
    }

    public func update(context: Context) {
        context.coordinator.value = context.atomContext.watch(atom)[keyPath: keyPath]
    }

    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.value = value
    }
}
