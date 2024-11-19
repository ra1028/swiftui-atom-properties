import SwiftUI

/// A property wrapper type that can watch the given atom conforms to ``ObservableObjectAtom``.
///
/// It starts watching the atom when the view accesses the ``wrappedValue``, and when the atom changes,
/// the view invalidates its appearance and recomputes the body.
///
/// See also ``Watch`` to have read-only access and ``WatchState`` to write value of ``StateAtom``.
/// The interface of this property wrapper follows `@StateObject`.
///
/// ## Example
///
/// ```swift
/// class Counter: ObservableObject {
///     @Published var count = 0
///
///     func plus(_ value: Int) {
///         count += value
///     }
/// }
///
/// struct CounterAtom: ObservableObjectAtom, Hashable {
///     func object(context: Context) -> Counter {
///         Counter()
///     }
/// }
///
/// struct CounterView: View {
///     @WatchStateObject(CounterAtom())
///     var counter
///
///     var body: some View {
///         VStack {
///             Text("Count: \(counter.count)")    // Read property, and start watching.
///             Stepper(value: $counter.count) {}  // Use the property as a binding
///             Button("+100") {
///                 counter.plus(100)              // Call the method to update.
///             }
///         }
///     }
/// }
/// ```
///
@propertyWrapper
public struct WatchStateObject<Node: ObservableObjectAtom>: DynamicProperty {
    /// A wrapper of the underlying observable object that can create bindings to
    /// its properties using dynamic member lookup.
    @dynamicMemberLookup
    @MainActor
    public struct Wrapper {
        private let object: Node.Produced

        /// Returns a binding to the resulting value of the given key path.
        ///
        /// - Parameter keyPath: A key path to a specific resulting value.
        ///
        /// - Returns: A new binding.
        public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Node.Produced, T>) -> Binding<T> {
            Binding(
                get: { object[keyPath: keyPath] },
                set: { object[keyPath: keyPath] = $0 }
            )
        }

        fileprivate init(_ object: Node.Produced) {
            self.object = object
        }
    }

    private let atom: Node

    @ViewContext
    private var context

    /// Creates an instance with the atom to watch.
    public init(_ atom: Node, fileID: String = #fileID, line: UInt = #line) {
        self.atom = atom
        self._context = ViewContext(fileID: fileID, line: line)
    }

    /// The underlying observable object associated with the given atom.
    ///
    /// This property provides primary access to the value's data. However, you don't
    /// access ``wrappedValue`` directly. Instead, you use the property variable created
    /// with the `@WatchStateObject` attribute.
    /// Accessing this property starts watching the atom.
    #if swift(>=6) || hasFeature(DisableOutwardActorInference)
        @MainActor
    #endif
    public var wrappedValue: Node.Produced {
        context.watch(atom)
    }

    /// A projection of the state object that creates bindings to its properties.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the projected value, prefix the property variable with `$`.
    #if swift(>=6) || hasFeature(DisableOutwardActorInference)
        @MainActor
    #endif
    public var projectedValue: Wrapper {
        Wrapper(wrappedValue)
    }
}
