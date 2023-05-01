import SwiftUI

/// A view to override or monitor atoms in scope.
///
/// This view allows you to monitor changes of atoms used in descendant views by``AtomScope/observe(_:)``.
///
/// ```swift
/// AtomScope {
///     MyView()
/// }
/// .observe { snapshot in
///     if let count = snapshot.lookup(CounterAtom()) {
///         print(count)
///     }
/// }
/// ```
///
/// It inherits from the atom store provided by ``AtomRoot`` through environment values by default,
/// but sometimes SwiftUI can fail to pass environment values in the view-tree for some reason.
/// The typical example is that, in case you use SwiftUI view inside UIKit view, it could fail as
/// SwiftUI can't pass environment values to UIKit across boundaries.
/// In that case, you can wrap the view with ``AtomScope`` and pass a view context to it so that
/// the descendant views can explicitly inherit the store.
///
/// ```swift
/// @ViewContext
/// var context
///
/// var body: some View {
///     MyUIViewWrappingView {
///         AtomScope(context) {
///             MySwiftUIView()
///         }
///     }
/// }
/// ```
///
/// Additionally, if for some reason your app cannot use ``AtomRoot`` to manage the store,
/// you can instead manage the store on your own and pass the instance to ``AtomScope``
/// to allow descendant views to use atoms.
///
/// ```swift
/// let store = AtomStore()
/// let rootView = AtomScope(store) {
///     RootView()
/// }
/// let window = UIWindow(frame: UIScreen.main.bounds)
/// window.rootViewController = UIHostingController(rootView: rootView)
/// window.makeKeyAndVisible()
/// ```
///
public struct AtomScope<Content: View>: View {
    private let store: StoreContext?
    private var overrides = Overrides()
    private var observers = [Observer]()
    private let content: Content

    @Environment(\.store)
    private var environmentStore

    /// Creates a new scope with the specified content.
    ///
    /// - Parameter content: The view content that inheriting from the parent.
    public init(@ViewBuilder content: () -> Content) {
        self.store = nil
        self.content = content()
    }

    /// Creates a new scope with the specified content that will be allowed to use atoms by
    /// passing a view context to explicitly make the descendant views inherit store.
    ///
    /// - Parameters:
    ///   - context: The parent view context that for inheriting store explicitly.
    ///   - content: The view content that inheriting from the parent.
    public init(
        _ context: AtomViewContext,
        @ViewBuilder content: () -> Content
    ) {
        self.store = context._store
        self.content = content()
    }

    /// Creates a new scope with the specified content that will be allowed to use atoms by
    /// passing a store object.
    ///
    /// - Parameters:
    ///   - store: An object that stores the state of atoms.
    ///   - content: The view content that inheriting from the parent.
    public init(
        _ store: AtomStore,
        @ViewBuilder content: () -> Content
    ) {
        self.store = StoreContext(store)
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        content.environment(
            \.store,
            (store ?? environmentStore).scoped(
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
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
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
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        mutating { $0.overrides.insert(atomType, with: value) }
    }

    /// For debugging, observes updates with a snapshot that captures a specific set of values of atoms.
    ///
    /// Use this to monitor and debugging the atoms or for producing side effects.
    ///
    /// - Parameter onUpdate: A closure to handle a snapshot of recent updates.
    ///
    /// - Returns: The self instance.
    public func observe(_ onUpdate: @escaping @MainActor (Snapshot) -> Void) -> Self {
        mutating { $0.observers.append(Observer(onUpdate: onUpdate)) }
    }
}

private extension AtomScope {
    func `mutating`(_ mutation: (inout Self) -> Void) -> Self {
        var view = self
        mutation(&view)
        return view
    }
}
