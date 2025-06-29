@usableFromInline
@MainActor
internal final class TransactionState {
    private var body: (@MainActor () -> @MainActor () -> Void)?
    private var cleanup: (@MainActor () -> Void)?

    let key: AtomKey

    private var termination: (@MainActor () -> Void)?
    private(set) var isTerminated = false

    init(
        key: AtomKey,
        _ body: @MainActor @escaping () -> @MainActor () -> Void
    ) {
        self.key = key
        self.body = { return body() } /// wrap `body` closure to allow for type inference in Xcode 26 toolchain
    }

    var onTermination: (@MainActor () -> Void)? {
        get { termination }
        set {
            guard !isTerminated else {
                newValue?()
                return
            }

            termination = newValue
        }

    }

    func begin() {
        cleanup = body?()
        body = nil
    }

    func commit() {
        cleanup?()
        cleanup = nil
    }

    func terminate() {
        isTerminated = true

        termination?()
        termination = nil
        body = nil
        commit()
    }
}
