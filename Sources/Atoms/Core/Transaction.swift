@usableFromInline
@MainActor
internal final class Transaction {
    private var _commit: (() -> Void)?

    let key: AtomKey

    private(set) var terminations = ContiguousArray<@MainActor () -> Void>()
    private(set) var isTerminated = false

    init(key: AtomKey, commit: @escaping () -> Void) {
        self.key = key
        self._commit = commit
    }

    func commit() {
        let commit = _commit
        _commit = nil
        commit?()
    }

    @usableFromInline
    func addTermination(_ termination: @MainActor @escaping () -> Void) {
        guard !isTerminated else {
            return termination()
        }

        terminations.append(termination)
    }

    func terminate() {
        isTerminated = true
        commit()

        let terminations = self.terminations
        self.terminations.removeAll()

        for termination in terminations {
            termination()
        }
    }
}
