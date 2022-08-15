public struct AsyncSequenceAtomLoader<Sequence: AsyncSequence>: RefreshableAtomLoader {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private let makeSequence: @MainActor (AtomNodeContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomNodeContext) -> Sequence) {
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

    public func refresh(context: Context, with value: Value) async -> Value {
        value
    }
}
