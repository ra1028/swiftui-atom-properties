public final class AsyncSequenceAtomState<Sequence: AsyncSequence>: RefreshableAtomState {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private var phase: Value?
    private let makeSequence: @MainActor (AtomRelationContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomRelationContext) -> Sequence) {
        self.makeSequence = makeSequence
    }

    public func value(context: Context) -> Value {
        if let phase = phase {
            return phase
        }

        let sequence = makeSequence(context.atomContext)
        let box = UnsafeUncheckedSendableBox(sequence)
        let task = Task {
            do {
                for try await element in box.unboxed {
                    if !Task.isCancelled {
                        self.phase = .success(element)
                        context.notifyUpdate()
                    }
                }
            }
            catch {
                if !Task.isCancelled {
                    self.phase = .failure(error)
                    context.notifyUpdate()
                }
            }
        }
        context.addTermination(task.cancel)

        let phase = Value.suspending
        self.phase = phase

        return phase
    }

    public func override(context: Context, with phase: Value) {
        self.phase = phase
    }

    public func refresh(context: Context) async -> Value {
        let sequence = makeSequence(context.atomContext)
        phase = .suspending

        do {
            for try await element in sequence {
                phase = .success(element)
            }
        }
        catch {
            phase = .failure(error)
        }

        context.notifyUpdate()
        return phase ?? .suspending
    }

    public func refreshOverride(context: Context, with phase: Value) async -> Value {
        self.phase = phase
        context.notifyUpdate()
        return phase
    }
}
