@usableFromInline
internal struct ScopeKey: Hashable {
    final class Token {}

    private let identifier: ObjectIdentifier

    var debugLabel: String {
        String(hashValue, radix: 36, uppercase: false)
    }

    init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
