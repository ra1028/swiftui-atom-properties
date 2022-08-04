public extension Atom {
    @MainActor
    func select<Selected: Equatable>(
        _ keyPath: KeyPath<Hook.Value, Selected>
    ) -> ModifiedAtom<Self, SelectModifier<Hook.Value, Selected>> {
        modifier(SelectModifier(keyPath: keyPath))
    }
}

public struct SelectModifier<Value, Selected: Equatable>: AtomModifier {
    public struct Key: Hashable {
        private let keyPath: KeyPath<Value, Selected>

        fileprivate init(keyPath: KeyPath<Value, Selected>) {
            self.keyPath = keyPath
        }
    }

    public final class Coordinator {
        internal var selected: Selected?
    }

    private let keyPath: KeyPath<Value, Selected>

    internal init(keyPath: KeyPath<Value, Selected>) {
        self.keyPath = keyPath
    }

    public var key: Key {
        Key(keyPath: keyPath)
    }

    public func shouldNotifyUpdate(newValue: Selected, oldValue: Selected) -> Bool {
        newValue != oldValue
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func get(context: Context) -> Selected? {
        context.coordinator.selected
    }

    public func set(value: Selected, context: Context) {
        context.coordinator.selected = value
    }

    public func update(context: Context, with value: Value) {
        set(value: value[keyPath: keyPath], context: context)
    }
}
