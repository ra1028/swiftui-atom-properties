public struct AsyncSequenceAtomValue<Sequence: AsyncSequence>: RefreshableAtomValue {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private let makeSequence: @MainActor (AtomRelationContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomRelationContext) -> Sequence) {
        self.makeSequence = makeSequence
    }

    public func get(context: Context) -> Value {
        let sequence = makeSequence(context.atomContext)
        let box = UnsafeUncheckedSendableBox(sequence)
        let task = Task {
            do {
                for try await element in box.unboxed {
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

    public func refresh(context: Context) -> AsyncStream<Value> {
        let sequence = makeSequence(context.atomContext)
        let box = UnsafeUncheckedSendableBox(sequence)

        return AsyncStream { continuation in
            continuation.yield(.suspending)

            let task = Task {
                do {
                    for try await element in box.unboxed {
                        continuation.yield(.success(element))
                    }
                }
                catch {
                    continuation.yield(.failure(error))
                }
            }

            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    task.cancel()
                }
            }
        }
    }

    public func refresh(context: Context, with value: Value) -> AsyncStream<Value> {
        AsyncStream { value }
    }
}
