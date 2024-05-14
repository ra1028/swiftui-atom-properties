@usableFromInline
internal struct Observer {
    let onUpdate: @MainActor (Snapshot) -> Void
}
