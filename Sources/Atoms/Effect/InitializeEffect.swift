public struct InitializeEffect: AtomEffect {
    private let action: () -> Void

    public init(perform action: @escaping () -> Void) {
        self.action = action
    }

    public func initialized(context: Context) {
        action()
    }
}
