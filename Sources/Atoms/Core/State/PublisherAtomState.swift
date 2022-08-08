import Combine

/// A state that is actual implementation of `PublisherAtom`.
public final class PublisherAtomState<Publisher: Combine.Publisher>: RefreshableAtomState {
    /// A type of value to provide.
    public typealias Value = AsyncPhase<Publisher.Output, Publisher.Failure>

    private var phase: Value?
    private let makePublisher: @MainActor (AtomRelationContext) -> Publisher

    internal init(makePublisher: @MainActor @escaping (AtomRelationContext) -> Publisher) {
        self.makePublisher = makePublisher
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> Value {
        if let phase = phase {
            return phase
        }

        let results = makePublisher(context.atomContext).results
        let box = UnsafeUncheckedSendableBox(results)
        let task = Task {
            for await result in box.unboxed {
                if !Task.isCancelled {
                    self.phase = AsyncPhase(result)
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
        let results = makePublisher(context.atomContext).results
        phase = .suspending

        for await result in results {
            phase = AsyncPhase(result)
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

private extension Publisher {
    var results: AsyncStream<Result<Output, Failure>> {
        AsyncStream { continuation in
            let cancellable = map(Result.success)
                .catch { Just(.failure($0)) }
                .sink(
                    receiveCompletion: { _ in
                        continuation.finish()
                    },
                    receiveValue: { result in
                        continuation.yield(result)
                    }
                )

            let box = UnsafeUncheckedSendableBox(cancellable)
            continuation.onTermination = { termination in
                switch termination {
                case .cancelled:
                    box.unboxed.cancel()

                case .finished:
                    break

                @unknown default:
                    break
                }
            }
        }
    }
}
