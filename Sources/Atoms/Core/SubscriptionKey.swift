internal struct SubscriptionKey: Hashable {
    private let identifier: ObjectIdentifier

    init(_ container: SubscriptionContainer) {
        identifier = ObjectIdentifier(container)
    }
}
