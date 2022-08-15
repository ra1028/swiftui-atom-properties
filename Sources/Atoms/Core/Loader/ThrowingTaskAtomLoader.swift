public struct ThrowingTaskAtomLoader<Success>: AsyncAtomLoader {
    public typealias Failure = Error
    public typealias Value = Task<Success, Failure>

    private let getValue: @MainActor (AtomNodeContext) async throws -> Success

    internal init(getValue: @MainActor @escaping (AtomNodeContext) async throws -> Success) {
        self.getValue = getValue
    }

    public func get(context: Context) -> Value {
        let task = Task {
            try await context.transaction(getValue)
        }
        return handle(context: context, with: task)
    }

    public func handle(context: Context, with task: Value) -> Value {
        context.addTermination(task.cancel)
        return task
    }

    public func refresh(context: Context) async -> Value {
        let task = Task {
            try await context.transaction(getValue)
        }
        return await refresh(context: context, with: task)
    }

    public func refresh(context: Context, with task: Value) async -> Value {
        await withTaskCancellationHandler {
            _ = await task.result
            return task
        } onCancel: {
            task.cancel()
        }
    }
}
