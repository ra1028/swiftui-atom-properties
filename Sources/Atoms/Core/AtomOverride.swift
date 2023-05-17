internal protocol AtomOverrideProtocol {
    associatedtype Node: Atom

    var value: (Node) -> Node.Loader.Value { get }

    func scoped(key: ScopeKey) -> any AtomScopedOverrideProtocol
}

internal struct AtomOverride<Node: Atom>: AtomOverrideProtocol {
    let value: (Node) -> Node.Loader.Value

    func scoped(key: ScopeKey) -> any AtomScopedOverrideProtocol {
        AtomScopedOverride<Node>(scopeKey: key, value: value)
    }
}

// As a workaround to the problem of not getting ScopeKey synchronously
// when the AtomRoot or AtomScope's override modifier is called, those modifiers
// temporarily register AtomOverride and convert them to AtomScopedOverride when
// their View body is evaluated. This is not ideal from a performance standpoint,
// so it will be improved as soon as an alternative way to grant per-scope keys
// independent of the SwiftUI lifecycle is came up.
internal protocol AtomScopedOverrideProtocol {
    var scopeKey: ScopeKey { get }
}

internal struct AtomScopedOverride<Node: Atom>: AtomScopedOverrideProtocol {
    let scopeKey: ScopeKey
    let value: (Node) -> Node.Loader.Value
}
