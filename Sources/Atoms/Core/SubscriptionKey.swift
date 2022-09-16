internal struct SubscriptionKey: Hashable {
    private let identifier: ObjectIdentifier

    let location: SourceLocation

    init(_ container: SubscriptionContainer, location: SourceLocation) {
        self.identifier = ObjectIdentifier(container)
        self.location = location
    }

    // Ignores `location` because it is a debugging metadata.
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
