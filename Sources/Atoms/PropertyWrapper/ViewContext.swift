import Combine
import SwiftUI

/// A property wrapper type that provides a context structure that to read, watch, and otherwise
/// interacting with atoms from views.
///
/// Through the provided context, the view can read, write, or some other interactions to atoms.
/// If the view watches an atom through the context, the view invalidates its appearance and recompute
/// the body when the atom value updates.
///
/// - SeeAlso: ``AtomViewContext``
///
/// ## Example
///
/// ```swift
/// struct CounterView: View {
///     @ViewContext
///     var context
///
///     var body: some View {
///         VStack {
///             Text("Count: \(context.watch(CounterAtom()))")  // Read value, and start watching.
///             Button("Increment") {
///                 context[CounterAtom()] += 1                 // Mutation which means simultaneous read-write access.
///             }
///             Button("Reset") {
///                 context.reset(CounterAtom())                // Reset to default value.
///             }
///         }
///     }
/// }
/// ```
///
@propertyWrapper
public struct ViewContext: DynamicProperty {
    @StateObject
    private var state = State()

    @Environment(\.store)
    private var _store

    private let location: SourceLocation

    /// Creates a view context.
    public init(fileID: String = #fileID, line: UInt = #line) {
        location = SourceLocation(fileID: fileID, line: line)
    }

    /// The underlying view context to interact with atoms.
    ///
    /// This property provides primary access to the view context. However you don't
    /// access ``wrappedValue`` directly.
    /// Instead, you use the property variable created with the `@ViewContext` attribute.
    public var wrappedValue: AtomViewContext {
        AtomViewContext(
            store: _store,
            container: state.container.wrapper(location: location),
            notifyUpdate: state.objectWillChange.send
        )
    }
}

private extension ViewContext {
    @MainActor
    final class State: ObservableObject {
        let container = SubscriptionContainer()
    }
}
