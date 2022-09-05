import SwiftUI

/// A property wrapper type that can watch and read-only access to the given atom.
///
/// When the view accesses ``wrappedValue``, it starts watching to the atom, and when the atom value
/// changes, the view invalidates its appearance and recomputes the body.
///
/// See also ``WatchState`` to write value of ``StateAtom`` and ``WatchStateObject`` to receive updates of
/// ``ObservableObjectAtom``.
///
/// ## Example
///
/// ```swift
/// struct CountDisplay: View {
///     @Watch(CounterAtom())
///     var count
///
///     var body: some View {
///         Text("Count: \(count)")  // Read value, and start watching.
///     }
/// }
/// ```
///
@propertyWrapper
public struct Watch<Node: Atom>: DynamicProperty {
    private let atom: Node

    @ViewContext
    private var context

    /// Creates a watch with the atom that to be watched.
    public init(_ atom: Node, fileID: String = #fileID, line: UInt = #line) {
        self.atom = atom
        self._context = ViewContext(fileID: fileID, line: line)
    }

    /// The underlying value associated with the given atom.
    ///
    /// This property provides primary access to the value's data. However, you don't
    /// access ``wrappedValue`` directly. Instead, you use the property variable created
    /// with the `@Watch` attribute.
    /// Accessing to this property starts watching to the atom.
    public var wrappedValue: Node.Loader.Value {
        context.watch(atom)
    }
}
