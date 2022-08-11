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

    public func refresh(context: Context) -> AsyncStream<Value> {
        let results = makePublisher(context.atomContext).results

        return AsyncStream { continuation in
            continuation.yield(.suspending)

            let task = Task {
                for await result in results {
                    continuation.yield(AsyncPhase(result))
                }
            }

            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    task.cancel()
                }
            }
        }
    }

    public func refresh(context: Context, with value: Value) -> AsyncStream<Value> {
        AsyncStream { value }
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
