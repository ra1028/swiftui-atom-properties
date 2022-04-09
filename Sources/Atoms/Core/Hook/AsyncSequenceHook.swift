/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct AsyncSequenceHook<Sequence: AsyncSequence>: AtomRefreshableHook {
    /// A type of value that this hook manages.
    public typealias Value = AsyncPhase<Sequence.Element, Error>

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var phase: Value?
    }

    private let sequence: @MainActor (AtomRelationContext) -> Sequence

    internal init(sequence: @MainActor @escaping (AtomRelationContext) -> Sequence) {
        self.sequence = sequence
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.phase ?? _assertingFallbackValue(context: context)
    }

    /// Initiates awaiting for the asynchronous elements of the given async sequence.
    public func update(context: Context) {
        let sequence = sequence(context.atomContext)
        let box = UnsafeUncheckedSendableBox(sequence)
        let task = Task {
            do {
                for try await element in box.unboxed {
                    if !Task.isCancelled {
                        context.coordinator.phase = .success(element)
                        context.notifyUpdate()
                    }
                }
            }
            catch {
                if !Task.isCancelled {
                    context.coordinator.phase = .failure(error)
                    context.notifyUpdate()
                }
            }
        }

        context.coordinator.phase = .suspending
        context.addTermination(task.cancel)
    }

    /// Overrides with the given value.
    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.phase = value
    }

    /// Refreshes and awaits until the given async sequence to be terminated.
    public func refresh(context: Context) async -> Value {
        let sequence = sequence(context.atomContext)
        context.coordinator.phase = .suspending

        do {
            for try await element in sequence {
                context.coordinator.phase = .success(element)
            }
        }
        catch {
            context.coordinator.phase = .failure(error)
        }

        context.notifyUpdate()
        return context.coordinator.phase ?? .suspending
    }

    /// Overrides with the given value and just notify update.
    public func refreshOverride(context: Context, with value: Value) async -> Value {
        context.coordinator.phase = value
        context.notifyUpdate()
        return value
    }
}
