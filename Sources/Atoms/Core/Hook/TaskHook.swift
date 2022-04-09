/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct TaskHook<Success>:
    AtomTaskHook,
    AtomRefreshableHook
{
    /// A type of value that this hook manages.
    public typealias Value = Task<Success, Never>

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var task: Value?
    }

    private let value: @MainActor (AtomRelationContext) async -> Success

    internal init(value: @MainActor @escaping (AtomRelationContext) async -> Success) {
        self.value = value
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.task ?? _assertingFallbackValue(context: context)
    }

    /// Initiates awaiting for the asynchronous value.
    public func update(context: Context) {
        let task = Task {
            await value(context.atomContext)
        }

        updateOverride(context: context, with: task)
    }

    /// Overrides with the given value.
    public func updateOverride(context: Context, with task: Value) {
        context.coordinator.task = task
        context.addTermination(task.cancel)
    }

    /// Refreshes and awaits until the given asynchronous resulting value to be available.
    public func refresh(context: Context) async -> Value {
        let task = Task {
            await value(context.atomContext)
        }

        return await refreshOverride(context: context, with: task)
    }

    /// Overrides with the given value and just notify update.
    public func refreshOverride(context: Context, with task: Value) async -> Value {
        context.coordinator.task = task

        return await withTaskCancellationHandler {
            task.cancel()
        } operation: {
            _ = await task.result
            context.notifyUpdate()
            return task
        }
    }
}
