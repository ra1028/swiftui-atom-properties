internal struct SubscriptionKey: Hashable, CustomStringConvertible {
    private let identifier: ObjectIdentifier

    init(_ container: SubscriptionContainer) {
        identifier = ObjectIdentifier(container)
    }

    var description: String {
        "Subscriber(\(hashValue))"
    }
}
