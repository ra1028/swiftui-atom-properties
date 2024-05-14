@usableFromInline
internal struct Observer: Sendable {
    let onUpdate: @MainActor @Sendable (Snapshot) -> Void
}
