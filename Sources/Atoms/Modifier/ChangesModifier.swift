public extension Atom where Loader.Value: Equatable {
    /// Prevents the atom from updating its child views or atoms when its new value is the
    /// same as its old value.
    ///
    /// ```swift
    /// struct FlagAtom: StateAtom, Hashable {
    ///     func defaultValue(context: Context) -> Bool {
    ///         true
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(FlagAtom().changes)
    ///     var flag
    ///
    ///     var body: some View {
    ///         if flag {
    ///             Text("true")
    ///         }
    ///         else {
    ///             Text("false")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    var changes: ModifiedAtom<Self, ChangesModifier<Loader.Value>> {
        modifier(ChangesModifier())
    }
}

/// A modifier that prevents the atom from updating its child views or atoms when
/// its new value is the same as its old value.
///
/// Use ``Atom/changes`` instead of using this modifier directly.
public struct ChangesModifier<T: Equatable>: AtomModifier {
    /// A type of base value to be modified.
    public typealias BaseValue = T

    /// A type of modified value to provide.
    public typealias Value = T

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {}

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// Returns a new value for the corresponding atom.
    public func modify(value: BaseValue, context: Context) -> Value {
        value
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
