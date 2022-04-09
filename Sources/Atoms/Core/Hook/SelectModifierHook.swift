/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct SelectModifierHook<Base: Atom, Value: Equatable>: AtomHook {
    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var value: Value?
    }

    private let base: Base
    private let keyPath: KeyPath<Base.Hook.Value, Value>

    internal init(base: Base, keyPath: KeyPath<Base.Hook.Value, Value>) {
        self.base = base
        self.keyPath = keyPath
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.value ?? _assertingFallbackValue(context: context)
    }

    /// Starts wathing to the base atom.
    public func update(context: Context) {
        context.coordinator.value = context.atomContext.watch(base)[keyPath: keyPath]
    }

    /// Overrides with the given value.
    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.value = value
    }
}
