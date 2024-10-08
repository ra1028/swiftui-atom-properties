/// An atom type that provides asynchronous, sequential elements of the given `AsyncSequence`
/// as an ``AsyncPhase`` value.
///
/// The sequential elements emitted by the `AsyncSequence` will be converted into an enum representation
/// ``AsyncPhase`` that changes overtime. When the sequence emits new elements, it notifies changes to
/// downstream atoms and views, so that they can consume it without suspension points which spawn with
/// `await` keyword.
///
/// ## Output Value
///
/// ``AsyncPhase``<Self.Sequence.Element, Error>
///
/// ## Example
///
/// ```swift
/// struct QuakeMonitorAtom: AsyncThrowingSequenceAtom, Hashable {
///     func sequence(context: Context) -> AsyncStream<Quake> {
///         AsyncStream { continuation in
///             let monitor = QuakeMonitor()
///             monitor.quakeHandler = { quake in
///                 continuation.yield(quake)
///             }
///             continuation.onTermination = { @Sendable _ in
///                 monitor.stopMonitoring()
///             }
///             monitor.startMonitoring()
///         }
///     }
/// }
///
/// struct QuakeMonitorView: View {
///     @Watch(QuakeMonitorAtom())
///     var quakes
///
///     var body: some View {
///         switch quakes {
///         case .suspending, .failure:
///             Text("Calm")
///
///         case .success(let quake):
///             Text("Quake: \(quake.date)")
///         }
///     }
/// }
/// ```
///
#if compiler(>=6)
    @available(macOS, deprecated: 15.0, message: "AsyncThrowingSequenceAtom has been replaced by AsyncSequenceAtom")  // swift-format-ignore
    @available(iOS, deprecated: 18.0, message: "AsyncThrowingSequenceAtom has been replaced by AsyncSequenceAtom")  // swift-format-ignore
    @available(watchOS, deprecated: 11.0, message: "AsyncThrowingSequenceAtom has been replaced by AsyncSequenceAtom")  // swift-format-ignore
    @available(tvOS, deprecated: 18.0, message: "AsyncThrowingSequenceAtom has been replaced by AsyncSequenceAtom")  // swift-format-ignore
    @available(visionOS, deprecated: 2.0, message: "AsyncThrowingSequenceAtom has been replaced by AsyncSequenceAtom")  // swift-format-ignore
#endif
public protocol AsyncThrowingSequenceAtom: AsyncAtom where Produced == AsyncPhase<Sequence.Element, Error> {
    /// The type of asynchronous sequence that this atom manages.
    associatedtype Sequence: AsyncSequence where Sequence.Element: Sendable

    /// Creates an asynchronous sequence to be started when this atom is actually used.
    ///
    /// The sequence that is produced by this method must be instantiated anew each time this method
    /// is called. Otherwise, it could throw a fatal error because Swift Concurrency  doesn't allow
    /// single `AsyncSequence` instance to be shared between multiple subscriptions.
    ///
    /// - Parameter context: A context structure to read, watch, and otherwise
    ///                      interact with other atoms.
    ///
    /// - Returns: An asynchronous sequence that produces asynchronous, sequential elements.
    @MainActor
    func sequence(context: Context) -> Sequence
}

public extension AsyncThrowingSequenceAtom {
    var producer: AtomProducer<Produced> {
        AtomProducer { context in
            let sequence = context.transaction(sequence)
            let task = Task {
                do {
                    for try await element in sequence {
                        if !Task.isCancelled {
                            context.update(with: .success(element))
                        }
                    }
                }
                catch {
                    if !Task.isCancelled {
                        context.update(with: .failure(error))
                    }
                }
            }

            context.onTermination = task.cancel
            return .suspending
        }
    }

    var refreshProducer: AtomRefreshProducer<Produced> {
        AtomRefreshProducer { context in
            let sequence = context.transaction(sequence)
            let task = Task {
                var phase = Produced.suspending

                do {
                    for try await element in sequence {
                        if !Task.isCancelled {
                            phase = .success(element)
                        }
                    }
                }
                catch {
                    if !Task.isCancelled {
                        phase = .failure(error)
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
