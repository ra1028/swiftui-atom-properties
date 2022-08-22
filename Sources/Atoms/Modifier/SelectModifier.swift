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
public struct SelectModifier<Value, Selected: Equatable>: AtomModifier {
    /// A type of modified value to provide.
    public typealias ModifiedValue = Selected

    /// A type representing the stable identity of this modifier.
    public struct Key: Hashable {
        private let keyPath: KeyPath<Value, Selected>

        fileprivate init(keyPath: KeyPath<Value, Selected>) {
            self.keyPath = keyPath
        }
    }

    private let keyPath: KeyPath<Value, Selected>

    internal init(keyPath: KeyPath<Value, Selected>) {
        self.keyPath = keyPath
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key(keyPath: keyPath)
    }

    /// Returns a new value for the corresponding atom.
    public func value(context: Context, with value: Value) -> Selected {
        value[keyPath: keyPath]
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with value: Selected) -> Selected {
        value
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldNotifyUpdate(newValue: Selected, oldValue: Selected) -> Bool {
        newValue != oldValue
    }
}
