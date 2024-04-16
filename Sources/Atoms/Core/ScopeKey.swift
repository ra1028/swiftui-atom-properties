@usableFromInline
internal struct ScopeKey: Hashable, CustomStringConvertible {
    final class Token {}

    private let identifier: ObjectIdentifier

    @usableFromInline
    var description: String {
        String(hashValue, radix: 36, uppercase: false)
    }

    init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
