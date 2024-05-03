public struct AtomRefreshProducer<Value, Coordinator> {
    internal typealias Context = AtomProducerContext<Value, Coordinator>

    internal let refresh: @MainActor (Context) async -> Value
    internal let refreshValue: @MainActor (Value, Context) async -> Value

    internal init(
        refresh: @MainActor @escaping (Context) async -> Value,
        refreshValue: @MainActor @escaping (Value, Context) async -> Value
    ) {
        self.refresh = refresh
        self.refreshValue = refreshValue
    }
}
