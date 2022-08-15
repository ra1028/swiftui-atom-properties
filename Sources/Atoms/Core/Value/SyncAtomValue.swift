public struct SyncAtomValue<T>: AtomValue {
    public typealias Value = T

    private let getValue: @MainActor (AtomRelationContext) -> T

    internal init(getValue: @MainActor @escaping (AtomRelationContext) -> T) {
        self.getValue = getValue
    }

    public func get(context: Context) -> T {
        context.withAtomContext(getValue)
    }

    public func lookup(context: Context, with value: T) -> T {
        value
    }
}
