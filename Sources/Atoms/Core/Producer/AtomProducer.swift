public struct AtomProducer<Value, Coordinator> {
    internal typealias Context = AtomProducerContext<Value, Coordinator>

    internal let getValue: @MainActor (Context) -> Value
    internal let manageValue: @MainActor (Value, Context) -> Value
    internal let shouldUpdate: @MainActor (Value, Value) -> Bool
    internal let performUpdate: @MainActor (() -> Void) -> Void

    internal init(
        getValue: @MainActor @escaping (Context) -> Value,
        manageValue: @MainActor @escaping (Value, Context) -> Value,
        shouldUpdate: @MainActor @escaping (Value, Value) -> Bool,
        performUpdate: @MainActor @escaping (() -> Void) -> Void
    ) {
        self.getValue = getValue
        self.manageValue = manageValue
        self.shouldUpdate = shouldUpdate
        self.performUpdate = performUpdate
    }
}
