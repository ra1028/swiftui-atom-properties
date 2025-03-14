@usableFromInline
internal struct Observer: Sendable {
    let onUpdate: @MainActor (Snapshot) -> Void
}
