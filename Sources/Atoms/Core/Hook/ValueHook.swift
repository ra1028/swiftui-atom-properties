/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct ValueHook<Value>: AtomHook {
    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var value: Value?
    }

    private let value: @MainActor (AtomRelationContext) -> Value

    internal init(value: @MainActor @escaping (AtomRelationContext) -> Value) {
        self.value = value
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.value ?? _assertingFallbackValue(context: context)
    }

    /// Instantiates the value and cache.
    public func update(context: Context) {
        context.coordinator.value = value(context.atomContext)
    }

    /// Overrides with the given value.
    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.value = value
    }
}
