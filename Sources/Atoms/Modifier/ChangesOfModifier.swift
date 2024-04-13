public extension Atom {
    /// Derives a partial property with the specified key path from the original atom and prevent it
    /// from updating its downstream when its new value is equivalent to old value.
    ///
    /// ```swift
    /// struct IntAtom: ValueAtom, Hashable {
    ///     func value(context: Context) -> Int {
    ///         12345
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(IntAtom().changes(of: \.description))
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
    func changes<T: Equatable>(
        of keyPath: KeyPath<Loader.Value, T>
    ) -> ModifiedAtom<Self, ChangesOfModifier<Loader.Value, T>> {
        modifier(ChangesOfModifier(keyPath: keyPath))
    }
}

/// A modifier that derives a partial property with the specified key path from the original atom
/// and prevent it from updating its downstream when its new value is equivalent to old value.
///
/// Use ``Atom/changes(of:)`` instead of using this modifier directly.
public struct ChangesOfModifier<BaseValue, T: Equatable>: AtomModifier {
    /// A type of modified value to provide.
    public typealias Value = T

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

    /// Manage given overridden value updates and cancellations.
    public func manageOverridden(value: Value, context: Context) -> Value {
        value
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldUpdate(newValue: Value, oldValue: Value) -> Bool {
        newValue != oldValue
    }
}
