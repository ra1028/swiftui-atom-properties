public struct AsyncSequenceAtomLoader<Sequence: AsyncSequence>: RefreshableAtomLoader {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private let makeSequence: @MainActor (AtomTransactionContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomTransactionContext) -> Sequence) {
        self.makeSequence = makeSequence
    }

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

    public func handle(context: Context, with value: Value) -> Value {
        value
    }

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

    public func refresh(context: Context, with value: Value) async -> Value {
        value
    }
}
