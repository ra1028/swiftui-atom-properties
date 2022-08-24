/// A loader protocol that represents an actual implementation of `ThrowingTaskAtom`.
public struct ThrowingTaskAtomLoader<Node: ThrowingTaskAtom>: AsyncAtomLoader {
    /// A type of success value.
    public typealias Success = Node.Value
    /// A type of failure value.
    public typealias Failure = Error
    /// A type of value to provide.
    public typealias Value = Task<Success, Failure>

    public typealias Coordinator = Node.Coordinator

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        let task = Task {
            try await context.transaction(atom.value)
        }
        return handle(context: context, with: task)
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with task: Value) -> Value {
        context.addTermination(task.cancel)
        return task
    }

    /// Refreshes and awaits until the asynchronous is finished and returns a final value.
    public func refresh(context: Context) async -> Value {
        let task = Task {
            try await context.transaction(atom.value)
        }
        return await refresh(context: context, with: task)
    }

    /// Refreshes and awaits for the passed value to be finished to yield values
    /// and returns a final value.
    public func refresh(context: Context, with task: Value) async -> Value {
        context.addTermination(task.cancel)

        return await withTaskCancellationHandler {
            _ = await task.result
            return task
        } onCancel: {
            task.cancel()
        }
    }
}
