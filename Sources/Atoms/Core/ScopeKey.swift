@usableFromInline
internal struct ScopeKey: Hashable, Sendable, CustomStringConvertible {
    final class Token {
        private(set) lazy var key = ScopeKey(token: self)
    }

    private let identifier: ObjectIdentifier

    @usableFromInline
    var description: String {
        String(hashValue, radix: 36, uppercase: false)
    }

    private init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
