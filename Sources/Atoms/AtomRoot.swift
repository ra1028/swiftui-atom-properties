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
/// Optionally, this component allows you to override a value of arbitrary atoms, that's useful
/// for dependency injection in testing.
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
    private var overrides = [OverrideKey: any AtomOverrideProtocol]()
    private var observers = [Observer]()
    private let content: Content

    /// Creates an atom root with the specified content that will be allowed to use atoms.
    ///
    /// - Parameter content: The content that uses atoms.
    public init(@ViewBuilder content: () -> Content) {
        self.storeHost = .tree
        self.content = content()
    }

    /// Creates a new scope with the specified content that will be allowed to use atoms by
    /// passing a store object.
    ///
    /// - Parameters:
    ///   - store: An object that stores the state of atoms.
    ///   - content: The view content that inheriting from the parent.
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
            TreeHostedStore(
                content: content,
                overrides: overrides,
                observers: observers
            )

        case .unmanaged(let store):
            UnmanagedStore(
                content: content,
                store: store,
                overrides: overrides,
                observers: observers
            )
        }
    }

    /// For debugging purposes, each time there is a change in the internal state,
    /// a snapshot is taken that captures the state of the atoms and their dependency graph
    /// at that point in time.
    ///
    /// - Parameter onUpdate: A closure to handle a snapshot of recent updates.
    ///
    /// - Returns: The self instance.
    public func observe(_ onUpdate: @escaping @MainActor (Snapshot) -> Void) -> Self {
        mutating(self) { $0.observers.append(Observer(onUpdate: onUpdate)) }
    }

    /// Overrides the atom value with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atom: An atom to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        mutating(self) { $0.overrides[OverrideKey(atom)] = AtomOverride(value: value) }
    }

    /// Overrides the atom value with the given value.
    ///
    /// Instead of overriding the particular instance of atom, this method overrides any atom that
    /// has the same metatype.
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atomType: An atom type to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        mutating(self) { $0.overrides[OverrideKey(atomType)] = AtomOverride(value: value) }
    }
}

private extension AtomRoot {
    enum StoreHost {
        case tree
        case unmanaged(store: AtomStore)
    }

    struct TreeHostedStore: View {
        @MainActor
        final class State: ObservableObject {
            let store = AtomStore()
            let token = ScopeKey.Token()
        }

        let content: Content
        let overrides: [OverrideKey: any AtomOverrideProtocol]
        let observers: [Observer]

        @StateObject
        private var state = State()

        var body: some View {
            content.environment(
                \.store,
                StoreContext(
                    state.store,
                    scopeKey: ScopeKey(token: state.token),
                    inheritedScopeKeys: [:],
                    observers: observers,
                    overrides: overrides
                )
            )
        }
    }

    struct UnmanagedStore: View {
        @MainActor
        final class State: ObservableObject {
            let token = ScopeKey.Token()
        }

        let content: Content
        let store: AtomStore
        let overrides: [OverrideKey: any AtomOverrideProtocol]
        let observers: [Observer]

        @StateObject
        private var state = State()

        var body: some View {
            content.environment(
                \.store,
                StoreContext(
                    store,
                    scopeKey: ScopeKey(token: state.token),
                    inheritedScopeKeys: [:],
                    observers: observers,
                    overrides: overrides
                )
            )
        }
    }
}
