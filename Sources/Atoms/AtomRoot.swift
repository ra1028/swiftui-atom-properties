import SwiftUI

/// A view that stores the state container of atoms and provides an internal store to view-tree
/// through environment values.
///
/// It must be the root of any views to manage the state of atoms used throughout the application.
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             AtomRoot {
///                 MyView()
///             }
///         }
///     }
/// }
/// ```
///
/// It optionally provides the modifier ``AtomRoot/override(_:with:)-20r5z`` to replace the value of
/// the specified atom, which is useful for dependency injection in testing.
///
/// ```swift
/// AtomRoot {
///     MyView()
/// }
/// .override(RepositoryAtom()) {
///     FakeRepository()
/// }
/// ```
///
/// In addition, all changes in atoms managed by ``AtomRoot`` can be monitored by passing an observer
/// to the ``AtomRoot/observe(_:)`` modifier.
///
/// ```swift
/// AtomRoot {
///     MyView()
/// }
/// .observe(Logger())
/// ```
///
public struct AtomRoot<Content: View>: View {
    @StateObject
    private var state: State
    private var overrides: AtomOverrides
    private var observers = [AtomObserver]()
    private let content: Content

    /// Creates an atom root with the specified content that will be allowed to use atoms.
    ///
    /// - Parameter content: The content that uses atoms.
    public init(@ViewBuilder content: () -> Content) {
        self._state = StateObject(wrappedValue: State())
        self.overrides = AtomOverrides()
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        content.environment(
            \.atomStore,
            Store(
                container: state.container,
                overrides: overrides,
                observers: observers
            )
        )
    }

    /// Overrides the atom value with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atom: An atom that to be overridden.
    ///   - value: A value that to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Hook.Value) -> Self {
        mutating { $0.overrides.insert(atom, with: value) }
    }

    /// Overrides the atom value with the given value.
    ///
    /// Instead of overriding the particular instance of atom, this method overrides any atom that
    /// has the same metatype.
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atomType: An atom type that to be overridden.
    ///   - value: A value that to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Hook.Value) -> Self {
        mutating { $0.overrides.insert(atomType, with: value) }
    }

    /// Observes changes in any atom values and its lifecycles.
    ///
    /// This method registers the given observer to notify changes of any atom values.
    /// It would be useful for monitoring and debugging the atoms and for producing side effects in
    /// the changes of particular atom.
    ///
    /// - SeeAlso: ``AtomObserver``
    ///
    /// - Parameter observer: A observer value to observe atom changes.
    ///
    /// - Returns: The self instance.
    public func observe<Observer: AtomObserver>(_ observer: Observer) -> Self {
        mutating { $0.observers.append(observer) }
    }
}

private extension AtomRoot {
    @MainActor
    final class State: ObservableObject {
        let container = StoreContainer()
    }

    func `mutating`(_ mutation: (inout Self) -> Void) -> Self {
        var view = self
        mutation(&view)
        return view
    }
}
