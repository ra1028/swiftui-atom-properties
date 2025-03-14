internal struct SubscriberKey: Hashable {
    @MainActor
    final class Token {
        private(set) lazy var key = SubscriberKey(token: self)
    }

    private let identifier: ObjectIdentifier

    private init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
