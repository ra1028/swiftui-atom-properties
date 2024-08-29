/// An atom effect that performs an arbitrary action when the atom is first used and initialized,
/// or once it is released and re-initialized again.
public struct InitializeEffect: AtomEffect {
    private let action: @MainActor () -> Void

    /// Creates an atom effect that performs the given action when the atom is initialized.
    public init(perform action: @MainActor @escaping () -> Void) {
        self.action = action
    }

    /// A lifecycle event that is triggered when the atom is first used and initialized,
    /// or once it is released and re-initialized again.
    public func initialized(context: Context) {
        action()
    }
}
