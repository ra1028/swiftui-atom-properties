public final class ThrowingTaskState<Success>: TaskAtomStateProtocol, RefreshableAtomStateProtocol {
    public typealias Value = Task<Success, Error>

    private var task: Value?
    private let getValue: @MainActor (AtomRelationContext) async throws -> Success

    internal init(getValue: @MainActor @escaping (AtomRelationContext) async throws -> Success) {
        self.getValue = getValue
    }

    public func value(context: Context) -> Value {
        if let task = task {
            return task
        }

        let task = Task {
            try await getValue(context.atomContext)
        }
        override(context: context, with: task)
        return task
    }

    public func terminate() {
        task = nil
    }

    public func override(context: Context, with task: Value) {
        self.task = task
        context.addTermination(task.cancel)
    }

    public func refresh(context: Context) async -> Value {
        let task = Task {
            try await getValue(context.atomContext)
        }

        return await refreshOverride(context: context, with: task)
    }

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
