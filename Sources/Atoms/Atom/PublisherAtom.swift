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
public protocol PublisherAtom: Atom {
    /// The type of publisher that this atom manages.
    associatedtype Publisher: Combine.Publisher

    /// Creates a publisher that to be subscribed when this atom is actually used.
    ///
    /// The publisher that is produced by this method must be instantiated anew each time this method
    /// is called. Otherwise, a cold publisher which has internal state can get result to produce
    /// non-reproducible results when it is newly subscribed.
    ///
    /// - Parameter context: A context structure that to read, watch, and otherwise
    ///                      interacting with other atoms.
    ///
    /// - Returns: A publisher that produces a sequence of values over time.
    @MainActor
    func publisher(context: Context) -> Publisher
}

public extension PublisherAtom {
    @MainActor
    var _loader: PublisherAtomLoader<Self> {
        PublisherAtomLoader(atom: self)
    }
}
