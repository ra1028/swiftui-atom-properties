/// A loader protocol that represents an actual implementation of `AsyncSequenceAtom`.
public struct AsyncSequenceAtomLoader<Node: AsyncSequenceAtom>: RefreshableAtomLoader {
    /// A type of value to provide.
    public typealias Value = AsyncPhase<Node.Sequence.Element, Error>

    /// A type to coordinate with the atom.
    public typealias Coordinator = Node.Coordinator

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func value(context: Context) -> Value {
        let sequence = context.transaction(atom.sequence)
        let task = Task {
            do {
                for try await element in sequence {
                    if !Task.isCancelled {
                        context.update(with: .success(element))
                    }
                }
            }
            catch {
                if !Task.isCancelled {
                    context.update(with: .failure(error))
                }
            }
        }

        context.addTermination(task.cancel)

        return .suspending
    }

    /// Manage given overridden value updates and cancellations.
    public func manageOverridden(value: Value, context: Context) -> Value {
        value
    }

    /// Refreshes and waits for the passed value to finish outputting values
    /// and returns a final value.
    public func refresh(context: Context) async -> Value {
        let sequence = context.transaction(atom.sequence)
        let task = Task {
            var phase = Value.suspending

            do {
                for try await element in sequence {
                    if !Task.isCancelled {
                        phase = .success(element)
                    }
                }
            }
            catch {
                phase = .failure(error)
            }

            return phase
        }

        context.addTermination(task.cancel)

        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    /// Refreshes and waits for the passed value to finish outputting values
    /// and returns a final value.
    public func refresh(overridden value: Value, context: Context) async -> Value {
        value
    }
}
