/// A state that is actual implementation of `ValueAtom`.
public final class ValueAtomState<Value>: AtomState {
    private var value: Value?
    private let getValue: @MainActor (AtomRelationContext) -> Value

    internal init(getValue: @MainActor @escaping (AtomRelationContext) -> Value) {
        self.getValue = getValue
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> Value {
        if let value = value {
            return value
        }

        let value = getValue(context.atomContext)
        self.value = value
        return value
    }

    /// Overrides the value with an arbitrary value.
    public func override(with value: Value, context: Context) {
        self.value = value
    }
}
