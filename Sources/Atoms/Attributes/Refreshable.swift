public protocol Refreshable where Self: Atom {
    typealias RefreshContext = AtomCurrentContext<Loader.Coordinator>

    @MainActor
    func refresh(context: RefreshContext) async -> Loader.Value
}
