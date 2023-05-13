/// A loader protocol that represents an actual implementation of `ThrowingTaskAtom`.
public struct ThrowingTaskAtomLoader<Node: ThrowingTaskAtom>: AsyncAtomLoader {
    /// A type of success value.
    public typealias Success = Node.Value

    /// A type of failure value.
    public typealias Failure = Error

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
            try await context.transaction(atom.value)
        }
        return associateOverridden(value: task, context: context)
    }

    /// Associates given value and handle updates and cancellations.
    public func associateOverridden(value: Value, context: Context) -> Value {
        context.addTermination(value.cancel)
        return value
    }

    /// Refreshes and awaits until the asynchronous is finished and returns a final value.
    public func refresh(context: Context) async -> Value {
        let task = Task {
            try await context.transaction(atom.value)
        }
        return await refreshOverridden(value: task, context: context)
    }

    /// Refreshes and awaits for the passed value to be finished to yield values
    /// and returns a final value.
    public func refreshOverridden(value: Value, context: Context) async -> Value {
        context.addTermination(value.cancel)

        return await withTaskCancellationHandler {
            _ = await value.result
            return value
        } onCancel: {
            value.cancel()
        }
    }
}
