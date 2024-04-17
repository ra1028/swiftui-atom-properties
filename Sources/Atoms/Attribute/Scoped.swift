/// An attribute protocol to scope the atom in descendant views, and prevent it from
/// being shared outside of the scope.
///
/// If multiple scopes are nested, you can define an arbitrary `scopeID` to ensure that
/// values are stored in a particular scope.
/// The atom with `scopeID` searches for the nearest ``AtomScope`` with the matching ID in
/// ancestor views, and if not found, the state is shared within the app.
///
/// Note that other atoms that depend on the scoped atom will be in a shared state and must be
/// given this attribute as well in order to scope them as well.
///
/// ## Example
///
/// ```swift
/// struct SearchScopeID: Hashable {}
///
/// struct SearchQueryAtom: StateAtom, Scoped, Hashable {
///     var scopeID: SearchScopeID {
///         SearchScopeID()
///     }
///
///     func defaultValue(context: Context) -> String {
///          ""
///     }
/// }
///
/// AtomScope(id: SearchScopeID()) {
///     SearchPane()
/// }
/// ```
///
public protocol Scoped where Self: Atom {
    /// A type of the scope ID which is to find a matching scope.
    associatedtype ScopeID: Hashable = DefaultScopeID

    /// A scope ID which is to find a matching scope.
    var scopeID: ScopeID { get }
}

public extension Scoped where ScopeID == DefaultScopeID {
    /// A scope ID which is to find a matching scope.
    var scopeID: ScopeID {
        DefaultScopeID()
    }
}

/// A default scope ID to find a matching scope inbetween scoped atoms and ``AtomScope``.
public struct DefaultScopeID: Hashable {
    /// Creates a new default scope ID which is always indentical.
    public init() {}
}
