internal struct ScopeID: Hashable {
    private let id: AnyHashable

    init(_ id: any Hashable) {
        self.id = AnyHashable(id)
    }
}
