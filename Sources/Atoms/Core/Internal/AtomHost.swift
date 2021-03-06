import Combine

internal final class AtomHost<Coordinator>: AtomHostBase {
    private let notifier = PassthroughSubject<Void, Never>()
    private var container = RelationshipContainer()
    private var terminations = Set<AnyCancellable>()

    var coordinator: Coordinator?
    var onDeinit: (() -> Void)?
    var onUpdate: ((Coordinator) -> Void)?

    deinit {
        onDeinit?()
    }

    var relationship: Relationship {
        Relationship(container: container)
    }

    func addTermination(_ termination: @MainActor @escaping () -> Void) {
        let termination = AnyCancellable { termination() }
        terminations.insert(termination)
    }

    func notifyUpdate() {
        notifier.send()

        if let coordinator = coordinator {
            onUpdate?(coordinator)
        }
    }

    func withTermination<T>(_ body: (AtomHost) -> T) -> T {
        // Keep the atom's assignment until the given process is finished.
        withExtendedLifetime(container) {
            terminate()
            return body(self)
        }
    }

    func withAsyncTermination<T>(_ body: (AtomHost) async -> T) async -> T {
        // Keep the atom's assignment until the given async process is finished.
        await container.withExtendedLifetime {
            terminate()
            return await body(self)
        }
    }

    func observe(_ notifyUpdate: @MainActor @escaping () -> Void) -> Relation {
        let cancellable = notifier.sink(receiveValue: { notifyUpdate() })
        return Relation(retaining: self, termination: cancellable.cancel)
    }
}

private extension AtomHost {
    func terminate() {
        coordinator = nil
        container = RelationshipContainer()
        terminations.removeAll()
    }

}

@usableFromInline
@MainActor
internal class AtomHostBase {}

private extension RelationshipContainer {
    func withExtendedLifetime<T>(_ body: () async -> T) async -> T {
        await body()
    }
}
