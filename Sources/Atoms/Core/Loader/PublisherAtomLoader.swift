import Combine

public struct PublisherAtomLoader<Publisher: Combine.Publisher>: RefreshableAtomLoader {
    public typealias Value = AsyncPhase<Publisher.Output, Publisher.Failure>

    private let makePublisher: @MainActor (AtomNodeContext) -> Publisher

    internal init(makePublisher: @MainActor @escaping (AtomNodeContext) -> Publisher) {
        self.makePublisher = makePublisher
    }

    public func get(context: Context) -> Value {
        let results = context.transaction(makePublisher).results
        let task = Task {
            for await result in results {
                if !Task.isCancelled {
                    context.update(with: AsyncPhase(result))
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
        let results = context.transaction(makePublisher).results
        var phase = Value.suspending

        for await result in results {
            phase = AsyncPhase(result)
        }

        return phase
    }

    public func refresh(context: Context, with value: Value) async -> Value {
        value
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

            continuation.onTermination = { termination in
                switch termination {
                case .cancelled:
                    cancellable.cancel()

                case .finished:
                    break

                @unknown default:
                    break
                }
            }
        }
    }
}
