public struct AsyncSequenceAtomValue<Sequence: AsyncSequence>: RefreshableAtomValue {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private let makeSequence: @MainActor (AtomRelationContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomRelationContext) -> Sequence) {
        self.makeSequence = makeSequence
    }

    public func get(context: Context) -> Value {
        let sequence = context.withAtomContext(makeSequence)
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

    public func lookup(context: Context, with value: Value) -> Value {
        value
    }

    public func refresh(context: Context) async -> Value {
        let sequence = context.withAtomContext(makeSequence)
        let box = UnsafeUncheckedSendableBox(sequence)
        var phase = Value.suspending

        do {
            for try await element in box.unboxed {
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
