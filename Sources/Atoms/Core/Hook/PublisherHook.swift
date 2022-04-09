import Combine

/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct PublisherHook<Publisher: Combine.Publisher>: AtomRefreshableHook {
    /// A type of value that this hook manages.
    public typealias Value = AsyncPhase<Publisher.Output, Publisher.Failure>

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var phase: Value?
    }

    private let publisher: @MainActor (AtomRelationContext) -> Publisher

    internal init(publisher: @MainActor @escaping (AtomRelationContext) -> Publisher) {
        self.publisher = publisher
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the value with the given context.
    public func value(context: Context) -> Value {
        context.coordinator.phase ?? _assertingFallbackValue(context: context)
    }

    /// Initiates subscribing to the publisher.
    public func update(context: Context) {
        let results = publisher(context.atomContext).results
        let box = UnsafeUncheckedSendableBox(results)
        let task = Task {
            for await result in box.unboxed {
                if !Task.isCancelled {
                    context.coordinator.phase = AsyncPhase(result)
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

    /// Refreshes and awaits until the publisher to be completed.
    public func refresh(context: Context) async -> Value {
        let results = publisher(context.atomContext).results
        context.coordinator.phase = .suspending

        for await result in results {
            context.coordinator.phase = AsyncPhase(result)
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
