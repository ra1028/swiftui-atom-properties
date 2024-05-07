public struct ReleaseEffect: AtomEffect {
    private let action: () -> Void

    public init(perform action: @escaping () -> Void) {
        self.action = action
    }

    public func released(context: Context) {
        action()
    }
}
