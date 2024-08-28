internal struct SubscriberKey: Hashable {
    @MainActor
    final class Token {}

    private let identifier: ObjectIdentifier

    init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
