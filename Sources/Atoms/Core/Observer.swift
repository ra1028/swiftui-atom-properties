@usableFromInline
@MainActor
internal struct Observer {
    let onUpdate: @MainActor (Snapshot) -> Void
}
