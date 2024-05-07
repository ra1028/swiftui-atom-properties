/// Produces the refreshed value of an atom.
public struct AtomRefreshProducer<Value, Coordinator> {
    internal typealias Context = AtomProducerContext<Value, Coordinator>

    internal let getValue: @MainActor (Context) async -> Value
    internal let refreshValue: @MainActor (Value, Context) async -> Void

    internal init(
        getValue: @MainActor @escaping (Context) async -> Value,
        refreshValue: @MainActor @escaping (Value, Context) async -> Void = { _, _ in }
    ) {
        self.getValue = getValue
        self.refreshValue = refreshValue
    }
}
