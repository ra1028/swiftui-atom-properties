/// An effect that doesn't produce any effects.
@available(*, deprecated, message: "`Atom/effect(context:)` now supports result builder syntax.")
public struct EmptyEffect: AtomEffect {
    /// Creates an empty effect.
    public init() {}
}
