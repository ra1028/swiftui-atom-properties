#if compiler(>=6)
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
    /// ``AsyncPhase``<Self.Sequence.Element, Self.Sequence.Failure>
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct QuakeMonitorAtom: AsyncSequenceAtom, Hashable {
    ///     func sequence(context: Context) -> AsyncThrowingStream<Quake, QuakeMonitorError> {
    ///         AsyncStream { continuation in
    ///             let monitor = QuakeMonitor()
    ///             monitor.quakeHandler = { result in
    ///                 continuation.yield(with: result)
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
    ///         case .failure(let error):
    ///             Text("Failed: \(error.localizedDescription)")
    ///
    ///         case .success(let quake):
    ///             Text("Quake: \(quake.date)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    public protocol AsyncSequenceAtom: AsyncAtom where Produced == AsyncPhase<Sequence.Element, Sequence.Failure> {
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

    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    public extension AsyncSequenceAtom {
        var producer: AtomProducer<Produced> {
            AtomProducer { context in
                let sequence = context.transaction(sequence)
                let task = Task {
                    do throws(Sequence.Failure) {
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

                    do throws(Sequence.Failure) {
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
#else
    /// Deprecated.
    ///
    /// - SeeAlso: ``AsyncThrowingSequenceAtom``
    @available(*, deprecated, renamed: "AsyncThrowingSequenceAtom")
    public typealias AsyncSequenceAtom = AsyncThrowingSequenceAtom
#endif
