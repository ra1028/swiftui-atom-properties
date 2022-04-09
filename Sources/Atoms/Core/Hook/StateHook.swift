/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct StateHook<Value>: AtomStateHook {
    /// A typealias of update observer will-set.
    public typealias WillSet = @MainActor (_ newValue: Value, _ oldValue: Value, _ context: AtomRelationContext) -> Void

    /// A typealias of update observer did-set.
    public typealias DidSet = @MainActor (_ newValue: Value, _ oldValue: Value, _ context: AtomRelationContext) -> Void

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var value: Value?
    }

    private let defaultValue: @MainActor (AtomRelationContext) -> Value
    private let willSet: WillSet
    private let didSet: DidSet

    internal init(
        defaultValue: @MainActor @escaping (AtomRelationContext) -> Value,
        willSet: @escaping WillSet,
        didSet: @escaping DidSet
    ) {
        self.defaultValue = defaultValue
        self.willSet = willSet
        self.didSet = didSet
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.value ?? _assertingFallbackValue(context: context)
    }

    /// Update to be the default value.
    public func update(context: Context) {
        context.coordinator.value = defaultValue(context.atomContext)
    }

    /// Overrides with the given value.
    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.value = value
    }

    /// Writes the given value and then notify update.
    public func set(value: Value, context: Context) {
        context.coordinator.value = value
        context.notifyUpdate()
    }

    /// Observes to changes in the state which is called just before the state is changed.
    public func willSet(newValue: Value, oldValue: Value, context: Context) {
        willSet(newValue, oldValue, context.atomContext)
    }

    /// Observes to changes in the state which is called just after the state is changed.
    public func didSet(newValue: Value, oldValue: Value, context: Context) {
        didSet(newValue, oldValue, context.atomContext)
    }
}
