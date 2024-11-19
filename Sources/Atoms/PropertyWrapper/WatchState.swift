import SwiftUI

/// A property wrapper type that can watch and read-write access to the given atom conforms
/// to ``StateAtom``.
///
/// It starts watching the atom when the view accesses the ``wrappedValue``, and when the atom changes,
/// the view invalidates its appearance and recomputes the body. However, if only write access is
/// performed, it doesn't start watching.
///
/// See also ``Watch`` to have read-only access and ``WatchStateObject`` to receive updates of
/// ``ObservableObjectAtom``.
/// The interface of this property wrapper follows `@State`.
///
/// ## Example
///
/// ```swift
/// struct CounterView: View {
///     @WatchState(CounterAtom())
///     var count
///
///     var body: some View {
///         VStack {
///             Text("Count: \(count)")    // Read value, and start watching.
///             Stepper(value: $count) {}  // Use as a binding
///             Button("+100") {
///                 count += 100           // Mutation which means simultaneous read-write access.
///             }
///         }
///     }
/// }
/// ```
///
@propertyWrapper
public struct WatchState<Node: StateAtom>: DynamicProperty {
    private let atom: Node

    @ViewContext
    private var context

    /// Creates an instance with the atom to watch.
    public init(_ atom: Node, fileID: String = #fileID, line: UInt = #line) {
        self.atom = atom
        self._context = ViewContext(fileID: fileID, line: line)
    }

    /// The underlying value associated with the given atom.
    ///
    /// This property provides primary access to the value's data. However, you don't
    /// access ``wrappedValue`` directly. Instead, you use the property variable created
    /// with the `@WatchState` attribute.
    /// Accessing to the getter of this property starts watching the atom, but doesn't
    /// by setting a new value.
    #if swift(>=6) || hasFeature(DisableOutwardActorInference)
        @MainActor
    #endif
    public var wrappedValue: Node.Produced {
        get { context.watch(atom) }
        nonmutating set { context.set(newValue, for: atom) }
    }

    /// A binding to the atom value.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the ``projectedValue``, prefix the property variable with `$`.
    /// Accessing this property itself does not start watching the atom, but does when
    /// the view accesses to the getter of the binding.
    #if swift(>=6) || hasFeature(DisableOutwardActorInference)
        @MainActor
    #endif
    public var projectedValue: Binding<Node.Produced> {
        context.binding(atom)
    }
}
