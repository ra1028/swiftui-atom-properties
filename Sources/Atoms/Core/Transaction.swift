@usableFromInline
@MainActor
internal final class Transaction {
    private var _commit: (() -> Void)?

    let key: AtomKey

    private(set) var terminations = ContiguousArray<Termination>()
    private(set) var isTerminated = false

    init(key: AtomKey, commit: @escaping () -> Void) {
        self.key = key
        self._commit = commit
    }

    func commit() {
        _commit?()
        _commit = nil
    }

    @usableFromInline
    func addTermination(_ termination: Termination) {
        guard !isTerminated else {
            return termination()
        }

        terminations.append(termination)
    }

    func terminate() {
        for termination in terminations {
            termination()
        }

        terminations.removeAll()

        commit()
        isTerminated = true
    }
}
