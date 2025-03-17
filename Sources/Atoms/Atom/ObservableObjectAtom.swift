import Combine
import Foundation

/// An atom type that instantiates an observable object.
///
/// When published properties of the observable object provided through this atom changes, it
/// notifies updates to downstream atoms and views that are watching this atom.
/// In case you want to get another atom value from the context later by methods in that
/// observable object, you can pass it as ``AtomContext``.
///
/// - Note: If you watch other atoms through the context passed as parameter, the observable
///         object itself will be re-created with fresh state when the watching atom is updated.
///
/// ## Output Value
///
/// Self.ObjectType
///
/// ## Example
///
/// ```swift
/// class Contact: ObservableObject {
///     @Published var name = ""
///     @Published var age = 20
///
///     func haveBirthday() {
///         age += 1
///     }
/// }
///
/// struct ContactAtom: ObservableObjectAtom, Hashable {
///     func object(context: Context) -> Contact {
///         Contact()
///     }
/// }
///
/// struct ContactView: View {
///     @WatchStateObject(ContactAtom())
///     var contact
///
///     var body: some View {
///         VStack {
///             TextField("Enter your name", text: $contact.name)
///             Text("Age: \(contact.age)")
///             Button("Celebrate your birthday!") {
///                 contact.haveBirthday()
///             }
///         }
///     }
/// }
/// ```
///
public protocol ObservableObjectAtom: Atom where Produced == ObjectType {
    /// The type of observable object that this atom produces.
    associatedtype ObjectType: ObservableObject

    /// Creates an observed object when this atom is actually used.
    ///
    /// The observable object that returned from this method is managed internally and notifies
    /// its updates to downstream atoms and views are watching this atom.
    ///
    /// - Parameter context: A context structure to read, watch, and otherwise
    ///                      interact with other atoms.
    ///
    /// - Returns: An observable object that notifies its updates over time.
    @MainActor
    func object(context: Context) -> ObjectType
}

public extension ObservableObjectAtom {
    var producer: AtomProducer<Produced> {
        AtomProducer { context in
            context.transaction(object)
        } manageValue: { object, context in
            let cancellable = object
                .objectWillChange
                .map { @Sendable _ in }
                .sinkLatest { [weak object] _ in
                    // A custom subscriber is used here, encompassing the following
                    // three behaviours.
                    //
                    // 1. It ensures that updates are performed on the main actor because `ObservableObject`
                    //    is not constrained to be isolated to the main actor.
                    // 2. It always performs updates asynchronously to ensure the object to be updated as
                    //    `objectWillChange` emits events before the update.
                    // 3. It adopts the latest event and cancels the previous update when successive events
                    //    arrive.
                    if let object, !context.isTerminated {
                        context.update(with: object)
                    }
                }

            context.onTermination = {
                cancellable.cancel()
            }
        }
    }
}

private extension Publisher where Output: Sendable, Failure == Never {
    func sinkLatest(receiveValue: @MainActor @escaping (Output) -> Void) -> AnyCancellable {
        let subscriber = Subscribers.SinkLatestOnMainActor(receiveValue: receiveValue)
        receive(subscriber: subscriber)
        return AnyCancellable(subscriber)
    }
}

private extension Subscribers {
    final class SinkLatestOnMainActor<Input: Sendable>: Combine.Subscriber, Cancellable {
        private var receiveValue: (@MainActor (Input) -> Void)?
        private var currentTask: Task<Void, Never>?
        private var lock = os_unfair_lock_s()

        init(receiveValue: @MainActor @escaping (Input) -> Void) {
            self.receiveValue = receiveValue
        }

        func receive(subscription: any Combine.Subscription) {
            subscription.request(.unlimited)
        }

        func receive(_ input: Input) -> Demand {
            withLock {
                guard let receiveValue else {
                    return .none
                }

                currentTask?.cancel()
                currentTask = Task { @MainActor in
                    guard !Task.isCancelled else {
                        return
                    }
                    receiveValue(input)
                }

                return .unlimited
            }
        }

        func receive(completion: Completion<Never>) {}

        func cancel() {
            withLock {
                currentTask?.cancel()
                currentTask = nil
                receiveValue = nil
            }
        }

        func withLock<R>(_ body: () -> R) -> R {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return body()
        }
    }
}
