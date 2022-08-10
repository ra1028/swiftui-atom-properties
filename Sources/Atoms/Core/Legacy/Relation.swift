import Combine

@usableFromInline
@MainActor
internal final class Relation {
    private let host: AtomHostBase
    private let termination: AnyCancellable

    init(
        retaining host: AtomHostBase,
        termination: @escaping () -> Void
    ) {
        self.host = host
        self.termination = AnyCancellable(termination)
    }
}
