internal struct Termination {
    private let body: @MainActor () -> Void

    init(_ body: @escaping @MainActor () -> Void) {
        self.body = body
    }

    @MainActor
    func callAsFunction() {
        body()
    }
}
