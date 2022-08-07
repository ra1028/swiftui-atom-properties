public final class StateAtomState<Value>: AtomState {
    public typealias WillSet = @MainActor (
        _ newValue: Value,
        _ oldValue: Value,
        _ context: AtomRelationContext
    ) -> Void

    public typealias DidSet = @MainActor (
        _ newValue: Value,
        _ oldValue: Value,
        _ context: AtomRelationContext
    ) -> Void

    private var value: Value?
    private let getDefaultValue: @MainActor (AtomRelationContext) -> Value
    private let willSet: WillSet
    private let didSet: DidSet

    internal init(
        getDefaultValue: @MainActor @escaping (AtomRelationContext) -> Value,
        willSet: @escaping WillSet,
        didSet: @escaping DidSet
    ) {
        self.getDefaultValue = getDefaultValue
        self.willSet = willSet
        self.didSet = didSet
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

    public func willSet(newValue: Value, oldValue: Value, context: Context) {
        willSet(newValue, oldValue, context.atomContext)
    }

    public func didSet(newValue: Value, oldValue: Value, context: Context) {
        didSet(newValue, oldValue, context.atomContext)
    }

    public func terminate() {
        value = nil
    }

    public func override(context: Context, with value: Value) {
        self.value = value
    }
}
