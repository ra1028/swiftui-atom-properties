@MainActor
internal struct Subscription {
    let location: SourceLocation
    let notifyUpdate: () -> Void
    let unsubscribe: () -> Void
}
