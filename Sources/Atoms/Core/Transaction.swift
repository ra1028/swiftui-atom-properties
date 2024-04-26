@usableFromInline
@MainActor
internal final class Transaction {
    private var body: (() -> () -> Void)?
    private var cleanup: (() -> Void)?

    let key: AtomKey

    private(set) var terminations = ContiguousArray<Termination>()
    private(set) var isTerminated = false

    init(key: AtomKey, _ body: @escaping () -> () -> Void) {
        self.key = key
        self.body = body
    }

    func begin() {
        cleanup = body?()
        body = nil
    }

    func commit() {
        cleanup?()
        cleanup = nil
    }

    @usableFromInline
    func addTermination(_ termination: @MainActor @escaping () -> Void) {
        guard !isTerminated else {
            return termination()
        }

        terminations.append(Termination(action: termination))
    }

    func terminate() {
        isTerminated = true
        body = nil
        commit()

        let terminations = self.terminations
        self.terminations.removeAll()

        for termination in terminations {
            termination.action()
        }
    }
}
