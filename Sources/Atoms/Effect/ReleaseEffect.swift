/// An atom effect that performs an arbitrary action when the atom is no longer watched and released.
public struct ReleaseEffect: AtomEffect {
    private let action: @MainActor () -> Void

    /// Creates an atom effect that performs the given action when the atom is released.
    public init(perform action: @MainActor @escaping () -> Void) {
        self.action = action
    }

    /// A lifecycle event that is triggered when the atom is no longer watched and released.
    public func released(context: Context) {
        action()
    }
}
