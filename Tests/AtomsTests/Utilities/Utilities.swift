import Combine

@testable import Atoms

final class Object {}

struct UniqueKey: Hashable {}

final class TestEffect: AtomEffect {
    var initializingCount = 0
    var initializedCount = 0
    var updatedCount = 0
    var releasedCount = 0

    func initializing(context: Context) {
        initializingCount += 1
    }

    func initialized(context: Context) {
        initializedCount += 1
    }

    func updated(context: Context) {
        updatedCount += 1
    }

    func released(context: Context) {
        releasedCount += 1
    }
}

final class TestObservableObject: ObservableObject, @unchecked Sendable {
    @Published
    private(set) var updatedCount = 0

    func update() {
        updatedCount += 1
    }
}

final class AsyncThrowingStreamPipe<Element>: @unchecked Sendable {
    private(set) var stream: AsyncThrowingStream<Element, any Error>
    private(set) var continuation: AsyncThrowingStream<Element, any Error>.Continuation

    init() {
        (stream, continuation) = AsyncThrowingStream.makeStream()
    }

    func reset() {
        (stream, continuation) = AsyncThrowingStream.makeStream()
    }
}

final class ResettableSubject<Output, Failure: Error>: Publisher, Subject {
    private var internalSubject = PassthroughSubject<Output, Failure>()

    func receive<S: Combine.Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        internalSubject.receive(subscriber: subscriber)
    }

    func send(_ value: Output) {
        internalSubject.send(value)
    }

    func send(completion: Subscribers.Completion<Failure>) {
        internalSubject.send(completion: completion)
    }

    func send(subscription: any Combine.Subscription) {
        internalSubject.send(subscription: subscription)
    }

    func reset() {
        internalSubject = PassthroughSubject()
    }
}

extension StoreContext {
    static var dummy: StoreContext {
        .root(
            store: AtomStore(),
            scopeKey: ScopeKey.Token().key
        )
    }

    static func root(store: AtomStore, scopeKey: ScopeKey) -> StoreContext {
        .root(
            store: store,
            scopeKey: scopeKey,
            observers: [],
            overrideContainer: OverrideContainer()
        )
    }

    func scoped(scopeID: ScopeID, scopeKey: ScopeKey) -> StoreContext {
        scoped(
            scopeID: scopeID,
            scopeKey: scopeKey,
            observers: [],
            overrideContainer: OverrideContainer()
        )
    }
}

extension AtomKey {
    init(_ atom: some Atom) {
        self.init(atom, scopeKey: nil)
    }
}

extension Atoms.Subscription {
    init(update: @MainActor @escaping () -> Void = {}) {
        let location = SourceLocation()
        self.init(location: location, update: update)
    }
}

extension AtomCache {
    init(atom: Node, value: Node.Produced) {
        self.init(atom: atom, value: value, initializedScope: nil)
    }
}

extension AtomCache: Equatable where Node: Equatable, Node.Produced: Equatable {
    // NB: Synthesized Equatable conformance doesn't work well in Xcode 14.0.1.
    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.atom == rhs.atom && lhs.value == rhs.value
    }
}

extension TransactionState {
    convenience init(key: AtomKey) {
        self.init(key: key, { {} })
    }
}

extension OverrideContainer {
    func addingOverride<Node: Atom>(for atom: Node, with value: @MainActor @escaping (Node) -> Node.Produced) -> Self {
        mutating(self) { $0.addOverride(for: atom, with: value) }
    }

    func addingOverride<Node: Atom>(for atomType: Node.Type, with value: @MainActor @escaping (Node) -> Node.Produced) -> Self {
        mutating(self) { $0.addOverride(for: atomType, with: value) }
    }
}

extension Task where Success == Never, Failure == Never {
    static func yield(
        isolation: isolated (any Actor)? = #isolation,
        @_inheritActorContext until predicate: () -> Bool
    ) async {
        while !predicate() {
            await yield()
        }
    }
}
