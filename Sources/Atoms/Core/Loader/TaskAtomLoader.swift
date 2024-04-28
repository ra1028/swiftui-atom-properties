/// A loader protocol that represents an actual implementation of `TaskAtom`.
public struct TaskAtomLoader<Node: TaskAtom>: AsyncAtomLoader {
    /// A type of success value.
    public typealias Success = Node.Value

    /// A type of failure value.
    public typealias Failure = Never

    /// A type of value to provide.
    public typealias Value = Task<Success, Failure>

    /// A type to coordinate with the atom.
    public typealias Coordinator = Node.Coordinator

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func value(context: Context) -> Value {
        let task = Task {
            await context.transaction(atom.value)
        }
        return manageOverridden(value: task, context: context)
    }

    /// Manage given overridden value updates and cancellations.
    public func manageOverridden(value: Value, context: Context) -> Value {
        context.onTermination = value.cancel
        return value
    }

    /// Refreshes and waits until the asynchronous process is finished and returns a final value.
    public func refresh(context: Context) async -> Value {
        let task = Task {
            await context.transaction(atom.value)
        }
        return await refresh(overridden: task, context: context)
    }

    /// Refreshes and waits for the passed value to finish outputting values
    /// and returns a final value.
    public func refresh(overridden value: Value, context: Context) async -> Value {
        context.onTermination = value.cancel

        return await withTaskCancellationHandler {
            _ = await value.result
            return value
        } onCancel: {
            value.cancel()
        }
    }
}
