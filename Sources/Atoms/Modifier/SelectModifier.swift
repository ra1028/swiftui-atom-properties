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
    func select<Value: Equatable>(
        _ keyPath: KeyPath<Hook.Value, Value>
    ) -> SelectModifierAtom<Self, Value> {
        SelectModifierAtom(base: self, keyPath: keyPath)
    }
}

/// An atom that selects the partial value of the specified key path from the original atom.
///
/// You can also use ``Atom/select(_:)`` to constract this atom.
public struct SelectModifierAtom<Base: Atom, Value: Equatable>: Atom {
    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {
        private let base: Base.Key
        private let keyPath: KeyPath<Base.Hook.Value, Value>

        fileprivate init(
            base: Base.Key,
            keyPath: KeyPath<Base.Hook.Value, Value>
        ) {
            self.base = base
            self.keyPath = keyPath
        }
    }

    private let base: Base
    private let keyPath: KeyPath<Base.Hook.Value, Value>

    /// Creates a new atom instance with given base atom and key path.
    public init(base: Base, keyPath: KeyPath<Base.Hook.Value, Value>) {
        self.base = base
        self.keyPath = keyPath
    }

    /// A unique value used to identify the atom internally.
    public var key: Key {
        Key(base: base.key, keyPath: keyPath)
    }

    /// The hook for managing the state of this atom internally.
    public var hook: SelectModifierHook<Base, Value> {
        Hook(base: base, keyPath: keyPath)
    }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    public func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool {
        newValue != oldValue
    }
}
