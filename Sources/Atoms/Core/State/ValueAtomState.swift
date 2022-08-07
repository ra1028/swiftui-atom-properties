public final class ValueAtomState<Value>: AtomState {
    private var value: Value?
    private let getValue: @MainActor (AtomRelationContext) -> Value

    internal init(getValue: @MainActor @escaping (AtomRelationContext) -> Value) {
        self.getValue = getValue
    }

    public func value(context: Context) -> Value {
        if let value = value {
            return value
        }

        let value = getValue(context.atomContext)
        self.value = value
        return value
    }

    public func terminate() {
        value = nil
    }

    public func override(context: Context, with value: Value) {
        self.value = value
    }
}
