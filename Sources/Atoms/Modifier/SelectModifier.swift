public extension Atom {
    /// Selects a partial property with the specified key path from the original atom.
    ///
    /// When this modifier is used, the atom provides the partial value which conforms to `Equatable`
    /// and prevent the view from updating its child view if the new value is equivalent to old value.
    ///
    /// ```swift
    /// struct IntAtom: ValueAtom, Hashable {
    ///     func value(context: Context) -> Int {
    ///         12345
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(IntAtom().select(\.description))
    ///     var description
    ///
    ///     var body: some View {
    ///         Text(description)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A key path for the property of the original atom value.
    ///
    /// - Returns: An atom that provides the partial property of the original atom value.
    @MainActor
    func select<Selected: Equatable>(
        _ keyPath: KeyPath<Hook.Value, Selected>
    ) -> ModifiedAtom<Self, SelectModifier<Hook.Value, Selected>> {
        modifier(SelectModifier(keyPath: keyPath))
    }
}

/// A modifier that selects the partial value of the specified key path
/// from the original atom.
///
/// Use ``Atom/select(_:)`` instead of using this modifier directly.
public struct SelectModifier<Value, Selected: Equatable>: AtomModifier {
    /// A type representing the stable identity of this modifier.
    public struct Key: Hashable {
        private let keyPath: KeyPath<Value, Selected>

        fileprivate init(keyPath: KeyPath<Value, Selected>) {
            self.keyPath = keyPath
        }
    }

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var selected: Selected?
    }

    private let keyPath: KeyPath<Value, Selected>

    internal init(keyPath: KeyPath<Value, Selected>) {
        self.keyPath = keyPath
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key(keyPath: keyPath)
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldNotifyUpdate(newValue: Selected, oldValue: Selected) -> Bool {
        newValue != oldValue
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets the value with the given context.
    public func get(context: Context) -> Selected? {
        context.coordinator.selected
    }

    /// Sets a value with the given context.
    public func set(value: Selected, context: Context) {
        context.coordinator.selected = value
    }

    /// Update the current value by modifying the given value.
    public func update(context: Context, with value: Value) {
        set(value: value[keyPath: keyPath], context: context)
    }
}
