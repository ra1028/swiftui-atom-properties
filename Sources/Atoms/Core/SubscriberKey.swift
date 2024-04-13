internal struct SubscriberKey: Hashable {
    final class Token {}

    private let identifier: ObjectIdentifier

    init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
