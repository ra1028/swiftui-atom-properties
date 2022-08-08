/// A state that is actual implementation of `AsyncSequenceAtom`.
public final class AsyncSequenceAtomState<Sequence: AsyncSequence>: RefreshableAtomState {
    /// A type of value to provide.
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    private var phase: Value?
    private let makeSequence: @MainActor (AtomRelationContext) -> Sequence

    internal init(makeSequence: @MainActor @escaping (AtomRelationContext) -> Sequence) {
        self.makeSequence = makeSequence
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
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

    /// Overrides the value with an arbitrary value.
    public func override(context: Context, with phase: Value) {
        self.phase = phase
    }

    /// Refreshes and awaits until the asynchronous value to be updated.
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

    /// Overrides with the given value and awaits until the value to be updated.
    public func refreshOverride(context: Context, with phase: Value) async -> Value {
        self.phase = phase
        context.notifyUpdate()
        return phase
    }
}