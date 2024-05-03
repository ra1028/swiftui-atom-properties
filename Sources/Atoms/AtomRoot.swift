import SwiftUI

/// A view that stores the state of atoms.
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
/// This view allows you to override a value of arbitrary atoms, which is useful
/// for dependency injection in testing.
///
/// ```swift
/// AtomRoot {
///     RootView()
/// }
/// .override(APIClientAtom()) {
///     StubAPIClient()
/// }
/// ```
///
/// You can also observe updates with a snapshot that captures a specific set of values of atoms.
///
/// ```swift
/// AtomRoot {
///     MyView()
/// }
/// .observe { snapshot in
///     if let count = snapshot.lookup(CounterAtom()) {
///         print(count)
///     }
/// }
/// ```
///
/// Additionally, if for some reason you want to manage the store on your own,
/// you can pass the instance to allow descendant views to store atom values
/// in the given store.
///
/// ```swift
/// let store = AtomStore()
///
/// struct Application: App {
///     var body: some Scene {
///         WindowGroup {
///             AtomRoot(storesIn: store) {
///                 RootView()
///             }
///         }
///     }
/// }
/// ```
///
public struct AtomRoot<Content: View>: View {
    private var storeHost: StoreHost
    private var overrides = [OverrideKey: any OverrideProtocol]()
    private var observers = [Observer]()
    private let content: Content

    /// Creates an atom root with the specified content that will be allowed to use atoms.
    ///
    /// - Parameter content: The descendant view content that provides context for atoms.
    public init(@ViewBuilder content: () -> Content) {
        self.storeHost = .tree
        self.content = content()
    }

    /// Creates a new scope with the specified content that will be allowed to use atoms by
    /// passing a store object.
    ///
    /// - Parameters:
    ///   - store: An object that stores the state of atoms.
    ///   - content: The descendant view content that provides context for atoms.
    public init(
        storesIn store: AtomStore,
        @ViewBuilder content: () -> Content
    ) {
        self.storeHost = .unmanaged(store: store)
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        switch storeHost {
        case .tree:
            TreeManaged(
                content: content,
                overrides: overrides,
                observers: observers
            )

        case .unmanaged(let store):
            Unmanaged(
                content: content,
                store: store,
                overrides: overrides,
                observers: observers
            )
        }
    }

    /// Observes the state changes with a snapshot that captures the whole atom states and
    /// their dependency graph at the point in time for debugging purposes.
    ///
    /// - Parameter onUpdate: A closure to handle a snapshot of recent updates.
    ///
    /// - Returns: The self instance.
    public func observe(_ onUpdate: @escaping @MainActor (Snapshot) -> Void) -> Self {
        mutating(self) { $0.observers.append(Observer(onUpdate: onUpdate)) }
    }

    /// Overrides the atoms with the given value.
    ///
    /// It will create and return the given value instead of the actual atom value when accessing
    /// the overridden atom in any scopes.
    ///
    /// - Parameters:
    ///   - atom: An atom to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Produced) -> Self {
        mutating(self) { $0.overrides[OverrideKey(atom)] = Override(isScoped: false, value: value) }
    }

    /// Overrides the atoms with the given value.
    ///
    /// It will create and return the given value instead of the actual atom value when accessing
    /// the overridden atom in any scopes.
    /// This method overrides any atoms that has the same metatype, instead of overriding
    /// the particular instance of atom.
    ///
    /// - Parameters:
    ///   - atomType: An atom type to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Produced) -> Self {
        mutating(self) { $0.overrides[OverrideKey(atomType)] = Override(isScoped: false, value: value) }
    }
}

private extension AtomRoot {
    enum StoreHost {
        case tree
        case unmanaged(store: AtomStore)
    }

    struct TreeManaged: View {
        @MainActor
        final class State: ObservableObject {
            let store = AtomStore()
            let token = ScopeKey.Token()
        }

        let content: Content
        let overrides: [OverrideKey: any OverrideProtocol]
        let observers: [Observer]

        @StateObject
        private var state = State()

        var body: some View {
            content.environment(
                \.store,
                StoreContext(
                    store: state.store,
                    scopeKey: ScopeKey(token: state.token),
                    inheritedScopeKeys: [:],
                    observers: observers,
                    scopedObservers: [],
                    overrides: overrides,
                    scopedOverrides: [:]
                )
            )
        }
    }

    struct Unmanaged: View {
        @MainActor
        final class State: ObservableObject {
            let token = ScopeKey.Token()
        }

        let content: Content
        let store: AtomStore
        let overrides: [OverrideKey: any OverrideProtocol]
        let observers: [Observer]

        @StateObject
        private var state = State()

        var body: some View {
            content.environment(
                \.store,
                StoreContext(
                    store: store,
                    scopeKey: ScopeKey(token: state.token),
                    inheritedScopeKeys: [:],
                    observers: observers,
                    scopedObservers: [],
                    overrides: overrides,
                    scopedOverrides: [:]
                )
            )
        }
    }
}
