/// An atom effect that performs an arbitrary action after the atom is first used and initialized,
/// or once it is released and re-initialized.
public struct InitializeEffect: AtomEffect {
    private let action: @MainActor () -> Void

    /// Creates an atom effect that performs the given action after the atom is initialized.
    public init(perform action: @MainActor @escaping () -> Void) {
        self.action = action
    }

    /// A lifecycle event that is triggered after the atom is first used and initialized,
    /// or once it is released and re-initialized.
    public func initialized(context: Context) {
        action()
    }
}
