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
    var producer: AtomProducer<Produced, Coordinator> {
        AtomProducer { context in
            context.transaction(object)
        } manageValue: { object, context in
            let cancellable = object
                .objectWillChange
                .sink { [weak object] _ in
                    // Wait until the object's property is set, because `objectWillChange`
                    // emits an event before the property is updated.
                    Task { @MainActor in
                        if !context.isTerminated, let object {
                            context.update(with: object)
                        }
                    }
                }

            context.onTermination = cancellable.cancel
        }
    }
}
