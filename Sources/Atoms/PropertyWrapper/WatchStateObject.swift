import SwiftUI

/// A property wrapper type that can watch the given atom conforms to ``ObservableObjectAtom``.
///
/// When the view accesses ``wrappedValue``, it starts watching to the atom, and when the atom changes,
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
    public struct Wrapper {
        private let object: Node.Loader.Value

        /// Returns a binding to the resulting value of the given key path.
        ///
        /// - Parameter keyPath: A key path to a specific resulting value.
        ///
        /// - Returns: A new binding.
        public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Node.Loader.Value, T>) -> Binding<T> {
            Binding(
                get: { object[keyPath: keyPath] },
                set: { object[keyPath: keyPath] = $0 }
            )
        }

        fileprivate init(_ object: Node.Loader.Value) {
            self.object = object
        }
    }

    private let atom: Node

    @ViewContext
    private var context

    /// Creates a watch with the atom that to be watched.
    public init(_ atom: Node, fileID: String = #fileID, line: UInt = #line) {
        self.atom = atom
        self._context = ViewContext(fileID: fileID, line: line)
    }

    /// The underlying observable object associated with the given atom.
    ///
    /// This property provides primary access to the value's data. However, you don't
    /// access ``wrappedValue`` directly. Instead, you use the property variable created
    /// with the `@WatchStateObject` attribute.
    /// Accessing to this property starts watching to the atom.
    public var wrappedValue: Node.Loader.Value {
        context.watch(atom)
    }

    /// A projection of the state object that creates bindings to its properties.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the projected value, prefix the property variable with `$`.
    public var projectedValue: Wrapper {
        Wrapper(wrappedValue)
    }
}
