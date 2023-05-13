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
    func select<Selected: Equatable>(
        _ keyPath: KeyPath<Loader.Value, Selected>
    ) -> ModifiedAtom<Self, SelectModifier<Loader.Value, Selected>> {
        modifier(SelectModifier(keyPath: keyPath))
    }
}

/// A modifier that selects the partial value of the specified key path
/// from the original atom.
///
/// Use ``Atom/select(_:)`` instead of using this modifier directly.
public struct SelectModifier<BaseValue, Selected: Equatable>: AtomModifier {
    /// A type of modified value to provide.
    public typealias Value = Selected

    /// A type representing the stable identity of this modifier.
    public struct Key: Hashable {
        private let keyPath: KeyPath<BaseValue, Value>

        fileprivate init(keyPath: KeyPath<BaseValue, Value>) {
            self.keyPath = keyPath
        }
    }

    private let keyPath: KeyPath<BaseValue, Value>

    internal init(keyPath: KeyPath<BaseValue, Value>) {
        self.keyPath = keyPath
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key(keyPath: keyPath)
    }

    /// Returns a new value for the corresponding atom.
    public func modify(value: BaseValue, context: Context) -> Value {
        value[keyPath: keyPath]
    }

    /// Associates given value and handle updates and cancellations.
    public func associateOverridden(value: Value, context: Context) -> Value {
        value
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldUpdate(newValue: Value, oldValue: Value) -> Bool {
        newValue != oldValue
    }
}
