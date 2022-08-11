public struct AsyncAtomValue<Success, Failure: Error>: TaskAtomValue {
    public typealias Value = Task<Success, Failure>

    private let getTask: @MainActor (AtomRelationContext) -> Value

    internal init(getTask: @MainActor @escaping (AtomRelationContext) -> Value) {
        self.getTask = getTask
    }

    public func get(context: Context) -> Value {
        let task = getTask(context.atomContext)
        context.addTermination(task.cancel)
        return task
    }

    public func refresh(context: Context) -> AsyncStream<Value> {
        let task = getTask(context.atomContext)
        return refresh(context: context, with: task)
    }

    public func refresh(context: Context, with task: Value) -> AsyncStream<Value> {
        AsyncStream(
            unfolding: {
                _ = await task.result
                return task
            },
            onCancel: {
                task.cancel()
            }
        )
    }
}
