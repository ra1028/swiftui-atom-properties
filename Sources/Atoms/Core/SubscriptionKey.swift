internal struct SubscriptionKey: Hashable, CustomStringConvertible {
    private let identifier: ObjectIdentifier
    private let location: SourceLocation

    init(_ container: SubscriptionContainer, location: SourceLocation) {
        self.identifier = ObjectIdentifier(container)
        self.location = location
    }

    var description: String {
        "\(location.fileID):\(location.line)"
    }

    // Ignores `location` because it is a debugging metadata.
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
