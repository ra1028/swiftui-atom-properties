@usableFromInline
@MainActor
internal struct Termination {
    private let body: @MainActor () -> Void

    @usableFromInline
    init(_ body: @escaping @MainActor () -> Void) {
        self.body = body
    }

    func callAsFunction() {
        body()
    }
}
