public struct ValueAtomLoader<T>: AtomLoader {
    public typealias Value = T

    private let getValue: @MainActor (AtomTransactionContext) -> T

    internal init(getValue: @MainActor @escaping (AtomTransactionContext) -> T) {
        self.getValue = getValue
    }

    public func get(context: Context) -> T {
        context.transaction(getValue)
    }

    public func handle(context: Context, with value: T) -> T {
        value
    }
}
