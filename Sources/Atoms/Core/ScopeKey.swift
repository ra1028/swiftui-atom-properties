@usableFromInline
internal struct ScopeKey: Hashable, Sendable, CustomStringConvertible {
    final class Token {
        private(set) lazy var key = ScopeKey(token: self)
    }

    private let identifier: ObjectIdentifier

    @usableFromInline
    var description: String {
        "0x\(String(UInt(bitPattern: identifier), radix: 16))"
    }

    private init(token: Token) {
        identifier = ObjectIdentifier(token)
    }
}
