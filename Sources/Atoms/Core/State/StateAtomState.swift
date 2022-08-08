public final class StateAtomState<Value>: AtomState {
    private var value: Value?
    private let getDefaultValue: @MainActor (AtomRelationContext) -> Value

    internal init(getDefaultValue: @MainActor @escaping (AtomRelationContext) -> Value) {
        self.getDefaultValue = getDefaultValue
    }

    public func value(context: Context) -> Value {
        if let value = value {
            return value
        }

        let value = getDefaultValue(context.atomContext)
        self.value = value
        return value
    }

    public func set(value: Value, context: Context) {
        self.value = value
        context.notifyUpdate()
    }

    public func override(context: Context, with value: Value) {
        self.value = value
    }
}
