/// A loader protocol that represents an actual implementation of `AsyncSequenceAtom`.
public struct AsyncSequenceAtomLoader<Sequence: AsyncSequence>: RefreshableAtomLoader {
    /// A type of value to provide.
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private let makeSequence: @MainActor (AtomTransactionContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomTransactionContext) -> Sequence) {
        self.makeSequence = makeSequence
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        let sequence = context.transaction(makeSequence)
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

    /// Refreshes and awaits until the asynchronous is finished and returns a final value.
    public func handle(context: Context, with value: Value) -> Value {
        value
    }

    /// Refreshes and awaits for the passed value to be finished to yield values
    /// and returns a final value.
    public func refresh(context: Context) async -> Value {
        let sequence = context.transaction(makeSequence)
        let task = Task { () -> Value in
            var phase = Value.suspending

            do {
                for try await element in sequence {
                    phase = .success(element)
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

    /// Refreshes and awaits for the passed value to be finished to yield values
    /// and returns a final value.
    public func refresh(context: Context, with value: Value) async -> Value {
        value
    }
}
