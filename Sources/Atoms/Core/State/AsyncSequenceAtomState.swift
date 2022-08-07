public final class AsyncSequenceAtomState<Sequence: AsyncSequence>: AtomState {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    internal var phase: Value?

    private let sequence: @MainActor (AtomRelationContext) -> Sequence

    internal init(sequence: @MainActor @escaping (AtomRelationContext) -> Sequence) {
        self.sequence = sequence
    }

    public func value(context: Context) -> Value {
        if let phase = phase {
            return phase
        }

        let sequence = sequence(context.atomContext)
        let box = UnsafeUncheckedSendableBox(sequence)
        let task = Task {
            do {
                for try await element in box.unboxed {
                    if !Task.isCancelled {
                        phase = .success(element)
                        context.notifyUpdate()
                    }
                }
            }
            catch {
                if !Task.isCancelled {
                    phase = .failure(error)
                    context.notifyUpdate()
                }
            }
        }
        context.addTermination(task.cancel)

        let initialPhase = Value.suspending
        phase = initialPhase

        return initialPhase
    }

    public func terminate() {
        phase = nil
    }
}
