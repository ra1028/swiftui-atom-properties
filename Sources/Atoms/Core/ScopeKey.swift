internal struct ScopeKey: Hashable {
    final class Token {}

    private let identifier: ObjectIdentifier

    var id: String {
        String(hashValue, radix: 36, uppercase: false)
    }

    init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
