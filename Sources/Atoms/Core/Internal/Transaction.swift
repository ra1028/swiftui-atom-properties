@usableFromInline
@MainActor
internal final class Transaction {
    @usableFromInline
    var dependencies = Set<AtomKey>()
    @usableFromInline
    var terminations = ContiguousArray<Termination>()
    @usableFromInline
    private(set) var isClosed = false

    func close() {
        isClosed = true
    }
}
