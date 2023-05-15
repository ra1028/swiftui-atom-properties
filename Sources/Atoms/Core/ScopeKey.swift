internal struct ScopeKey: Hashable {
    final class Token {}

    private let identifier: ObjectIdentifier

    init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
