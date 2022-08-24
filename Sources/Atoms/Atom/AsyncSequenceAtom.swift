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
/// struct QuakeMonitorAtom: AsyncSequenceAtom, Hashable {
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
public protocol AsyncSequenceAtom: Atom {
    /// The type of asynchronous sequence that this atom manages.
    associatedtype Sequence: AsyncSequence

    /// Creates an asynchronous sequence that to be started when this atom is actually used.
    ///
    /// The sequence that is produced by this method must be instantiated anew each time this method
    /// is called. Otherwise, it could throw a fatal error because Swift Concurrency  doesn't allow
    /// single `AsyncSequence` instance to be shared between multiple locations.
    ///
    /// - Parameter context: A context structure that to read, watch, and otherwise
    ///                      interacting with other atoms.
    ///
    /// - Returns: An asynchronous sequence that produces asynchronous, sequential elements.
    @MainActor
    func sequence(context: Context) -> Sequence
}

public extension AsyncSequenceAtom {
    @MainActor
    var _loader: AsyncSequenceAtomLoader<Self> {
        AsyncSequenceAtomLoader(atom: self)
    }
}
