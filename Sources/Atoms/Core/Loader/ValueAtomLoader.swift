public struct ValueAtomLoader<T>: AtomLoader {
    public typealias Value = T

    private let getValue: @MainActor (AtomNodeContext) -> T

    internal init(getValue: @MainActor @escaping (AtomNodeContext) -> T) {
        self.getValue = getValue
    }

    public func get(context: Context) -> T {
        context.transaction(getValue)
    }

    public func handle(context: Context, with value: T) -> T {
        value
    }
}
