/// A state that is actual implementation of `TaskAtom`.
public final class TaskAtomState<Success>: AsyncAtomState {
    /// A type of value to provide.
    public typealias Value = Task<Success, Never>

    private var task: Value?
    private let getValue: @MainActor (AtomRelationContext) async -> Success

    internal init(getValue: @MainActor @escaping (AtomRelationContext) async -> Success) {
        self.getValue = getValue
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> Value {
        if let task = task {
            return task
        }

        let task = Task {
            await getValue(context.atomContext)
        }
        override(context: context, with: task)

        return task
    }

    /// Overrides the value with an arbitrary value.
    public func override(context: Context, with task: Value) {
        self.task = task
        context.addTermination(task.cancel)
    }

    /// Refreshes and awaits until the asynchronous value to be updated.
    public func refresh(context: Context) async -> Value {
        let task = Task {
            await getValue(context.atomContext)
        }

        return await refreshOverride(context: context, with: task)
    }

    /// Overrides with the given value and awaits until the value to be updated.
    public func refreshOverride(context: Context, with task: Value) async -> Value {
        self.task = task

        return await withTaskCancellationHandler {
            task.cancel()
        } operation: {
            _ = await task.result
            context.notifyUpdate()
            return task
        }
    }
}