@usableFromInline
@MainActor
internal final class TransactionState {
    private var body: (() -> () -> Void)?
    private var cleanup: (() -> Void)?

    let key: AtomKey

    private var termination: (@MainActor () -> Void)?
    private(set) var isTerminated = false

    init(key: AtomKey, _ body: @escaping () -> () -> Void) {
        self.key = key
        self.body = body
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
