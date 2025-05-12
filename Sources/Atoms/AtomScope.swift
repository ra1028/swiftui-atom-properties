import SwiftUI

/// A view to override or monitor atoms in scope.
///
/// This view allows you to override a value of arbitrary atoms used in this scope, which is useful
/// for dependency injection in testing.
///
/// ```swift
/// AtomScope {
///     MyView()
/// }
/// .scopedOverride(APIClientAtom()) {
///     StubAPIClient()
/// }
/// ```
///
/// You can also observe updates with a snapshot that captures a specific set of values of atoms.
///
/// ```swift
/// AtomScope {
///     CounterView()
/// }
/// .scopedObserve { snapshot in
///     if let count = snapshot.lookup(CounterAtom()) {
///         print(count)
///     }
/// }
/// ```
///
public struct AtomScope<Content: View>: View {
    private let inheritance: Inheritance
    private var observers = [Observer]()
    private var overrideContainer = OverrideContainer()
    private let content: Content

    /// Creates a new scope with the specified content.
    ///
    /// - Parameters:
    ///   - id: An identifier represents this scope used for matching with scoped atoms.
    ///   - content: The descendant view content that provides scoped context for atoms.
    public init<ID: Hashable>(id: ID = DefaultScopeID(), @ViewBuilder content: () -> Content) {
        let scopeID = ScopeID(id)
        self.inheritance = .environment(scopeID: scopeID)
        self.content = content()
    }

    /// Creates a new scope with the specified content that will be allowed to use atoms by
    /// passing a view context to explicitly make the descendant views inherit store.
    ///
    /// - Parameters:
    ///   - context: The parent view context that for inheriting store explicitly.
    ///   - content: The descendant view content that provides scoped context for atoms.
    @available(*, deprecated, message: "Use `AtomDerivedScope` instead")
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
        case .environment(let scopeID):
            WithEnvironment(
                scopeID: scopeID,
                observers: observers,
                overrideContainer: overrideContainer,
                content: content
            )

        case .context(let context):
            AtomDerivedScope(context) {
                content
            }
        }
    }

    /// Observes the state changes with a snapshot that captures the whole atom states and
    /// their dependency graph at the point in time for debugging purposes.
    ///
    /// Note that unlike ``AtomRoot/observe(_:)``, this observes only the state changes of atoms
    /// initialized in this scope.
    ///
    /// - Note: It ignores the observers if this scope inherits the parent scope.
    ///
    /// - Parameter onUpdate: A closure to handle a snapshot of recent updates.
    ///
    /// - Returns: The self instance.
    public func scopedObserve(_ onUpdate: @MainActor @escaping (Snapshot) -> Void) -> Self {
        if case .context = inheritance {
            assertionFailure(
                "[Atoms] AtomScope now ignores the given scoped observers if it's inheriting an ancestor scope. This will be deprecated soon."
            )
            return self
        }
        return mutating(self) { $0.observers.append(Observer(onUpdate: onUpdate)) }
    }

    /// Override the atoms used in this scope with the given value.
    ///
    /// It will create and return the given value instead of the actual atom value when accessing
    /// the overridden atom in this scope.
    ///
    /// This only overrides atoms used in this scope and never be inherited to a nested scopes.
    ///
    /// - Note: It ignores the overrides if this scope inherits the parent scope.
    ///
    /// - Parameters:
    ///   - atom: An atom to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func scopedOverride<Node: Atom>(_ atom: Node, with value: @MainActor @escaping (Node) -> Node.Produced) -> Self {
        if case .context = inheritance {
            assertionFailure(
                "[Atoms] AtomScope now ignores the given scoped overrides if it's inheriting an ancestor scope. This will be deprecated soon."
            )
            return self
        }
        return mutating(self) { $0.overrideContainer.addOverride(for: atom, with: value) }
    }

    /// Override the atoms used in this scope with the given value.
    ///
    /// It will create and return the given value instead of the actual atom value when accessing
    /// the overridden atom in this scope.
    /// This method overrides any atoms that has the same metatype, instead of overriding
    /// the particular instance of atom.
    ///
    /// This only overrides atoms used in this scope and never be inherited to a nested scopes.
    ///
    /// - Note: It ignores the overrides if this scope inherits the parent scope.
    ///
    /// - Parameters:
    ///   - atomType: An atom type to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    ///
    /// - Returns: The self instance.
    public func scopedOverride<Node: Atom>(_ atomType: Node.Type, with value: @MainActor @escaping (Node) -> Node.Produced) -> Self {
        if case .context = inheritance {
            assertionFailure(
                "[Atoms] AtomScope now ignores the given scoped overrides if it's inheriting an ancestor scope. This will be deprecated soon."
            )
            return self
        }
        return mutating(self) { $0.overrideContainer.addOverride(for: atomType, with: value) }
    }
}

private extension AtomScope {
    enum Inheritance {
        case environment(scopeID: ScopeID)
        case context(AtomViewContext)
    }

    struct WithEnvironment: View {
        let scopeID: ScopeID
        let observers: [Observer]
        let overrideContainer: OverrideContainer
        let content: Content

        @State
        private var scopeToken = ScopeKey.Token()
        @Environment(\.store)
        private var environmentStore

        var body: some View {
            content.environment(
                \.store,
                environmentStore?.scoped(
                    scopeID: scopeID,
                    scopeKey: scopeToken.key,
                    observers: observers,
                    overrideContainer: overrideContainer
                )
            )
        }
    }
}
