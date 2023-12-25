public protocol Refreshable where Self: Atom {
    typealias RefreshContext = AtomUpdatedContext<Loader.Coordinator>

    @MainActor
    func refresh(context: RefreshContext) async -> Loader.Value
}
