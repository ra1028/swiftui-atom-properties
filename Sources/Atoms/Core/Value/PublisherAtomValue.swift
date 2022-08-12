import Combine

public struct PublisherAtomValue<Publisher: Combine.Publisher>: RefreshableAtomValue {
    public typealias Value = AsyncPhase<Publisher.Output, Publisher.Failure>

    private let makePublisher: @MainActor (AtomRelationContext) -> Publisher

    internal init(makePublisher: @MainActor @escaping (AtomRelationContext) -> Publisher) {
        self.makePublisher = makePublisher
    }

    public func get(context: Context) -> Value {
        let results = makePublisher(context.atomContext).results
        let box = UnsafeUncheckedSendableBox(results)
        let task = Task {
            for await result in box.unboxed {
                if !Task.isCancelled {
                    context.update(with: AsyncPhase(result))
                }
            }
        }

        context.addTermination(task.cancel)
        return .suspending
    }

    public func refresh(context: Context) async -> Value {
        let results = makePublisher(context.atomContext).results
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
