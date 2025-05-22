/// An atom effect that performs an arbitrary action before the atom is first used and initialized,
/// or once it is released and re-initialized.
public struct InitializingEffect: AtomEffect {
    private let action: @MainActor () -> Void

    /// Creates an atom effect that performs the given action before the atom is initialized.
    public init(perform action: @MainActor @escaping () -> Void) {
        self.action = action
    }

    /// A lifecycle event that is triggered before the atom is first used and initialized,
    /// or once it is released and re-initialized.
    public func initializing(context: Context) {
        action()
    }
}
