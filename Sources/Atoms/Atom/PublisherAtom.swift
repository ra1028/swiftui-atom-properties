import Combine

/// An atom type that provides a sequence of values of the given `Publisher` as an ``AsyncPhase`` value.
///
/// The sequential values emitted by the `Publisher` will be converted into an enum representation
/// ``AsyncPhase`` that changes overtime. When the publisher emits new results, it notifies changes to
/// downstream atoms and views, so that they can consume it without managing subscription.
///
/// ## Output Value
///
/// AsyncPhase<Self.Publisher.Output, Self.Publisher.Failure>
///
/// ## Example
///
/// ```swift
/// struct TimerAtom: PublisherAtom, Hashable {
///     func publisher(context: Context) -> AnyPublisher<Date, Never> {
///         Timer.publish(every: 1, on: .main, in: .default)
///             .autoconnect()
///             .eraseToAnyPublisher()
///     }
/// }
///
/// struct TimerView: View {
///     @Watch(TimerAtom())
///     var timer
///
///     var body: some View {
///         switch timer {
///         case .suspending:
///             Text("Waiting")
///
///         case .success(let date):
///             Text("Now: \(date)")
///         }
///     }
/// }
/// ```
///
public protocol PublisherAtom: AsyncAtom where Produced == AsyncPhase<Publisher.Output, Publisher.Failure> {
    /// The type of publisher that this atom manages.
    associatedtype Publisher: Combine.Publisher

    /// Creates a publisher to be subscribed when this atom is actually used.
    ///
    /// The publisher that is produced by this method must be instantiated anew each time this method
    /// is called. Otherwise, a cold publisher which has internal state can get result to produce
    /// non-reproducible results when it is newly subscribed.
    ///
    /// - Parameter context: A context structure to read, watch, and otherwise
    ///                      interact with other atoms.
    ///
    /// - Returns: A publisher that produces a sequence of values over time.
    @MainActor
    func publisher(context: Context) -> Publisher
}

public extension PublisherAtom {
    var producer: AtomProducer<Produced, Coordinator> {
        AtomProducer { context in
            let results = context.transaction(publisher).results
            let task = Task {
                for await result in results {
                    if !Task.isCancelled {
                        context.update(with: AsyncPhase(result))
                    }
                }
            }

            context.onTermination = task.cancel
            return .suspending
        }
    }

    var refreshProducer: AtomRefreshProducer<Produced, Coordinator> {
        AtomRefreshProducer { context in
            let results = context.transaction(publisher).results
            let task = Task {
                var phase = Produced.suspending

                for await result in results {
                    if !Task.isCancelled {
                        phase = AsyncPhase(result)
                    }
                }

                return phase
            }

            context.onTermination = task.cancel

            return await withTaskCancellationHandler {
                await task.value
            } onCancel: {
                task.cancel()
            }
        }
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
                if case .cancelled = termination {
                    cancellable.cancel()
                }
            }
        }
    }
}
