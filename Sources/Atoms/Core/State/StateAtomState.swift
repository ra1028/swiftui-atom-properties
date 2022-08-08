/// A state that is an actual implementation of `StateAtom`.
public final class StateAtomState<Value>: AtomState {
    private var value: Value?
    private let getDefaultValue: @MainActor (AtomRelationContext) -> Value

    internal init(getDefaultValue: @MainActor @escaping (AtomRelationContext) -> Value) {
        self.getDefaultValue = getDefaultValue
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> Value {
        if let value = value {
            return value
        }

        let value = getDefaultValue(context.atomContext)
        self.value = value
        return value
    }

    /// Set a new value and then notifiy update to downstream atoms and views.
    public func set(value: Value, context: Context) {
        self.value = value
        context.notifyUpdate()
    }

    /// Overrides the value with an arbitrary value.
    public func override(context: Context, with value: Value) {
        self.value = value
    }
}
