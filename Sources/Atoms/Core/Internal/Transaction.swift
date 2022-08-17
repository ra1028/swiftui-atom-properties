@usableFromInline
@MainActor
internal final class Transaction {
    private var _commit: (() -> Void)?

    let key: AtomKey

    private(set) var isTerminated = false

    init(key: AtomKey, commit: @escaping () -> Void) {
        self.key = key
        self._commit = commit
    }

    func commit() {
        _commit?()
        _commit = nil
    }

    func terminate() {
        commit()
        isTerminated = true
    }
}
