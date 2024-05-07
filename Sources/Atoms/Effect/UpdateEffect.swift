public struct UpdateEffect: AtomEffect {
    private let action: () -> Void

    public init(perform action: @escaping () -> Void) {
        self.action = action
    }

    public func updated(context: Context) {
        action()
    }
}
