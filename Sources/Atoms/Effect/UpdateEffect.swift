/// An atom effect that performs an arbitrary action when the atom is updated.
public struct UpdateEffect: AtomEffect {
    private let action: () -> Void

    /// Creates an atom effect that performs the given action when the atom is updated.
    public init(perform action: @escaping () -> Void) {
        self.action = action
    }

    /// A lifecycle event that is triggered when the atom is updated.
    public func updated(context: Context) {
        action()
    }
}
