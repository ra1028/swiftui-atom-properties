import Combine

public final class PublisherAtomState<Publisher: Combine.Publisher>: RefreshableAtomState {
    public typealias Value = AsyncPhase<Publisher.Output, Publisher.Failure>

    private var phase: Value?
    private let makePublisher: @MainActor (AtomRelationContext) -> Publisher

    internal init(makePublisher: @MainActor @escaping (AtomRelationContext) -> Publisher) {
        self.makePublisher = makePublisher
    }

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

    public func override(context: Context, with phase: Value) {
        self.phase = phase
    }

    public func refresh(context: Context) async -> Value {
        let results = makePublisher(context.atomContext).results
        phase = .suspending

        for await result in results {
            phase = AsyncPhase(result)
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
