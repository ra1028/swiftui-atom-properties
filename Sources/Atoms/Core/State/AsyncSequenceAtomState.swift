public final class AsyncSequenceAtomState<Sequence: AsyncSequence>: AtomRefreshableState {
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private var phase: Value?
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
        let task = Task { [weak self] in
            guard let self = self else {
                return
            }

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

    public func terminate() {
        phase = nil
    }

    public func override(context: Context, with phase: Value) {
        self.phase = phase
    }

    public func refresh(context: Context) async -> Value {
        let sequence = sequence(context.atomContext)
        let phase = Value.suspending
        self.phase = phase

        do {
            for try await element in sequence {
                self.phase = .success(element)
            }
        }
        catch {
            self.phase = .failure(error)
        }

        context.notifyUpdate()
        return phase
    }

    public func refreshOverride(context: Context, with phase: Value) async -> Value {
        self.phase = phase
        context.notifyUpdate()
        return phase
    }
}
