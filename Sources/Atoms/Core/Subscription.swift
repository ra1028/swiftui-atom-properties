@usableFromInline
@MainActor
internal struct Subscription {
    let location: SourceLocation
    let update: () -> Void
}
