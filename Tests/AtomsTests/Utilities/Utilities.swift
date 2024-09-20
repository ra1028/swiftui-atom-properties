import Combine

@testable import Atoms

final class Object {}

struct UniqueKey: Hashable {}

final class TestEffect: AtomEffect {
    var initializedCount = 0
    var updatedCount = 0
    var releasedCount = 0

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
    private(set) var stream: AsyncThrowingStream<Element, Error>
    private(set) var continuation: AsyncThrowingStream<Element, Error>.Continuation

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

    func send(subscription: Combine.Subscription) {
        internalSubject.send(subscription: subscription)
    }

    func reset() {
        internalSubject = PassthroughSubject()
    }
}

extension StoreContext {
    init(
        store: AtomStore = AtomStore(),
        observers: [Observer] = [],
        overrides: [OverrideKey: any OverrideProtocol] = [:]
    ) {
        self.init(
            store: store,
            scopeKey: ScopeKey(token: ScopeKey.Token()),
            observers: observers,
            overrides: overrides
        )
    }

    init(
        store: AtomStore = AtomStore(),
        scopeKey: ScopeKey,
        observers: [Observer] = [],
        overrides: [OverrideKey: any OverrideProtocol] = [:]
    ) {
        self.init(
            store: store,
            scopeKey: scopeKey,
            inheritedScopeKeys: [:],
            observers: observers,
            scopedObservers: [],
            overrides: overrides,
            scopedOverrides: [:]
        )
    }
}

extension AtomKey {
    init(_ atom: some Atom) {
        self.init(atom, scopeKey: nil)
    }
}

extension Atoms.Subscription {
    init(update: @MainActor @Sendable @escaping () -> Void = {}) {
        let location = SourceLocation()
        self.init(location: location, update: update)
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
