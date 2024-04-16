import SwiftUI

/// A view to override or monitor atoms in scope.
///
/// This view allows you to monitor changes of atoms used in descendant views by``AtomScope/observe(_:)``.
///
/// ```swift
/// AtomScope {
///     CounterView()
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
///         AtomScope(inheriting: context) {
///             MySwiftUIView()
///         }
///     }
/// }
/// ```
///
public struct AtomScope<Content: View>: View {
    private let inheritance: Inheritance
    private var overrides = [OverrideKey: any AtomOverrideProtocol]()
    private var observers = [Observer]()
    private let content: Content

    /// Creates a new scope with the specified content.
    ///
    /// - Parameter content: The view content that inheriting from the parent.
    public init(@ViewBuilder content: () -> Content) {
        self.inheritance = .environment
        self.content = content()
    }

    /// Creates a new scope with the specified content that will be allowed to use atoms by
    /// passing a view context to explicitly make the descendant views inherit store.
    ///
    /// - Parameters:
    ///   - context: The parent view context that for inheriting store explicitly.
    ///   - content: The view content that inheriting from the parent.
    public init(
        inheriting context: AtomViewContext,
        @ViewBuilder content: () -> Content
    ) {
        self.inheritance = .context(context)
        self.content = content()
    }

    /// The content and behavior of the view.
    public var body: some View {
        switch inheritance {
        case .environment:
            InheritedEnvironment(
                content: content,
                overrides: overrides,
                observers: observers
            )

        case .context(let context):
            InheritedContext(
                content: content,
                context: context,
                overrides: overrides,
                observers: observers
            )
        }
    }

    /// For debugging purposes, each time there is a change in the internal state,
    /// a snapshot is taken that captures the state of the atoms and their dependency graph
    /// at that point in time.
    ///
    /// Note that unlike observed by ``AtomRoot``, this is triggered only by internal state changes
    /// caused by atoms use in this scope.
    ///
    /// - Parameter onUpdate: A closure to handle a snapshot of recent updates.
    ///
    /// - Returns: The self instance.
    public func observe(_ onUpdate: @escaping @MainActor (Snapshot) -> Void) -> Self {
        mutating { $0.observers.append(Observer(onUpdate: onUpdate)) }
    }

    /// Override the atom value used in this scope with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// This only overrides atoms used in this scope and never be inherited to a nested scope.
    ///
    /// - Parameters:
    ///   - atom: An atom to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        mutating { $0.overrides[OverrideKey(atom)] = AtomOverride(value: value) }
    }

    /// Override the atom value used in this scope with the given value.
    ///
    /// Instead of overriding the particular instance of atom, this method overrides any atom that
    /// has the same metatype.
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// This only overrides atoms used in this scope and never be inherited to a nested scope.
    ///
    /// - Parameters:
    ///   - atomType: An atom type to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        mutating { $0.overrides[OverrideKey(atomType)] = AtomOverride(value: value) }
    }
}

private extension AtomScope {
    enum Inheritance {
        case environment
        case context(AtomViewContext)
    }

    struct InheritedEnvironment: View {
        @MainActor
        final class State: ObservableObject {
            let token = ScopeKey.Token()
        }

        let content: Content
        let overrides: [OverrideKey: any AtomOverrideProtocol]
        let observers: [Observer]

        @StateObject
        private var state = State()
        @Environment(\.store)
        private var environmentStore

        var body: some View {
            content.environment(
                \.store,
                environmentStore.scoped(
                    scopeKey: ScopeKey(token: state.token),
                    observers: observers,
                    overrides: overrides
                )
            )
        }
    }

    struct InheritedContext: View {
        let content: Content
        let context: AtomViewContext
        let overrides: [OverrideKey: any AtomOverrideProtocol]
        let observers: [Observer]

        var body: some View {
            content.environment(
                \.store,
                context._store.inherited(
                    observers: observers,
                    overrides: overrides
                )
            )
        }
    }

    func `mutating`(_ mutation: (inout Self) -> Void) -> Self {
        var view = self
        mutation(&view)
        return view
    }
}
