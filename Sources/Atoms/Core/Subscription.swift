@MainActor
internal struct Subscription {
    let location: SourceLocation
    let requiresObjectUpdate: Bool
    let notifyUpdate: () -> Void
    let unsubscribe: () -> Void
}
