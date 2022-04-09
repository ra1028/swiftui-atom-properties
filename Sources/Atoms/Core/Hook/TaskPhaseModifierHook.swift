/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct TaskPhaseModifierHook<Base: Atom>: AtomHook where Base.Hook: AtomTaskHook {
    /// A type of value that this hook manages.
    public typealias Value = AsyncPhase<Base.Hook.Success, Base.Hook.Failure>

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var phase: Value?
    }

    private let base: Base

    internal init(base: Base) {
        self.base = base
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.phase ?? _assertingFallbackValue(context: context)
    }

    /// Starts wathing to the base atom and initiates awaiting for its asynchronous value.
    public func update(context: Context) {
        let task = Task {
            let phase = await AsyncPhase(context.atomContext.watch(base).result)

            if !Task.isCancelled {
                context.coordinator.phase = phase
                context.notifyUpdate()
            }
        }

        context.coordinator.phase = .suspending
        context.addTermination(task.cancel)
    }

    /// Overrides with the given value.
    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.phase = value
    }
}
