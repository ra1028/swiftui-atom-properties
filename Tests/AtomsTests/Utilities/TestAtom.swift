import Atoms
import Combine

struct TestAtom<T: Hashable>: ValueAtom, Hashable {
    var value: T

    func value(context: Context) -> T {
        value
    }
}

struct TestValueAtom<T>: ValueAtom {
    var value: T
    var onUpdated: ((T, T) -> Void)?

    var key: UniqueKey {
        UniqueKey()
    }

    func value(context: Context) -> T {
        value
    }

    func updated(newValue: T, oldValue: T, context: UpdatedContext) {
        onUpdated?(newValue, oldValue)
    }
}

struct TestStateAtom<T>: StateAtom {
    var defaultValue: T
    var onUpdated: ((T, T) -> Void)?

    var key: UniqueKey {
        UniqueKey()
    }

    func defaultValue(context: Context) -> T {
        defaultValue
    }

    func updated(newValue: T, oldValue: T, context: UpdatedContext) {
        onUpdated?(newValue, oldValue)
    }
}

struct TestTaskAtom<T: Sendable>: TaskAtom {
    var getValue: () -> T
    var onUpdated: ((Task<T, Never>, Task<T, Never>) -> Void)?

    var key: UniqueKey {
        UniqueKey()
    }

    init(value: T) {
        self.init { value }
    }

    init(
        getValue: @escaping () -> T,
        onUpdated: ((Task<T, Never>, Task<T, Never>) -> Void)? = nil
    ) {
        self.getValue = getValue
        self.onUpdated = onUpdated
    }

    func value(context: Context) async -> T {
        getValue()
    }

    func updated(
        newValue: Task<T, Never>,
        oldValue: Task<T, Never>,
        context: UpdatedContext
    ) {
        onUpdated?(newValue, oldValue)
    }
}

struct TestThrowingTaskAtom<Success: Sendable>: ThrowingTaskAtom {
    var getResult: () -> Result<Success, Error>
    var onUpdated: ((Task<Success, Error>, Task<Success, Error>) -> Void)?

    var key: UniqueKey {
        UniqueKey()
    }

    init(result: Result<Success, Error>) {
        self.getResult = { result }
    }

    init(
        getResult: @escaping () -> Result<Success, Error>,
        onUpdated: ((Task<Success, Error>, Task<Success, Error>) -> Void)? = nil
    ) {
        self.getResult = getResult
        self.onUpdated = onUpdated
    }

    func value(context: Context) async throws -> Success {
        try getResult().get()
    }

    func updated(
        newValue: Task<Success, Error>,
        oldValue: Task<Success, Error>,
        context: UpdatedContext
    ) {
        onUpdated?(newValue, oldValue)
    }
}

struct TestPublisherAtom<Publisher: Combine.Publisher>: PublisherAtom {
    var makePublisher: () -> Publisher
    var onUpdated: ((AsyncPhase<Publisher.Output, Publisher.Failure>, AsyncPhase<Publisher.Output, Publisher.Failure>) -> Void)?

    var key: UniqueKey {
        UniqueKey()
    }

    func publisher(context: Context) -> Publisher {
        makePublisher()
    }

    func updated(
        newValue: AsyncPhase<Publisher.Output, Publisher.Failure>,
        oldValue: AsyncPhase<Publisher.Output, Publisher.Failure>,
        context: UpdatedContext
    ) {
        onUpdated?(newValue, oldValue)
    }
}

struct TestAsyncSequenceAtom<Sequence: AsyncSequence>: AsyncSequenceAtom {
    var makeSequence: () -> Sequence
    var onUpdated: ((AsyncPhase<Sequence.Element, Error>, AsyncPhase<Sequence.Element, Error>) -> Void)?

    var key: UniqueKey {
        UniqueKey()
    }

    func sequence(context: Context) -> Sequence {
        makeSequence()
    }

    func updated(
        newValue: AsyncPhase<Sequence.Element, Error>,
        oldValue: AsyncPhase<Sequence.Element, Error>,
        context: UpdatedContext
    ) {
        onUpdated?(newValue, oldValue)
    }
}
