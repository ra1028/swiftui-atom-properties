@usableFromInline
internal struct Subscription {
    let location: SourceLocation
    let update: @MainActor () -> Void
}
