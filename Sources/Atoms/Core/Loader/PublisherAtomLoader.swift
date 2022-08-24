import Combine

/// A loader protocol that represents an actual implementation of `PublisherAtom`.
public struct PublisherAtomLoader<Node: PublisherAtom>: RefreshableAtomLoader {
    /// A type of value to provide.
    public typealias Value = AsyncPhase<Node.Publisher.Output, Node.Publisher.Failure>

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        let results = context.transaction(atom.publisher).results
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

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with value: Value) -> Value {
        value
    }

    /// Refreshes and awaits until the asynchronous is finished and returns a final value.
    public func refresh(context: Context) async -> Value {
        let results = context.transaction(atom.publisher).results
        let task = Task { () -> Value in
            var phase = Value.suspending

            for await result in results {
                phase = AsyncPhase(result)
            }

            return phase
        }

        context.addTermination(task.cancel)

        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    /// Refreshes and awaits for the passed value to be finished to yield values
    /// and returns a final value.
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
