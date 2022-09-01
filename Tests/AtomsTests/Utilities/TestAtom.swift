import Atoms
import Combine

struct TestValueAtom<T: Hashable>: ValueAtom, Hashable {
    var value: T

    func value(context: Context) -> T {
        value
    }
}

struct TestStateAtom<T>: StateAtom {
    var defaultValue: T

    var key: UniqueKey {
        UniqueKey()
    }

    func defaultValue(context: Context) -> T {
        defaultValue
    }
}

struct TestTaskAtom<T>: TaskAtom {
    var getValue: () -> T

    var key: UniqueKey {
        UniqueKey()
    }

    init(value: T) {
        self.getValue = { value }
    }

    init(getValue: @escaping () -> T) {
        self.getValue = getValue
    }

    func value(context: Context) async -> T {
        getValue()
    }
}

struct TestThrowingTaskAtom<Success>: ThrowingTaskAtom {
    var getResult: () -> Result<Success, Error>

    var key: UniqueKey {
        UniqueKey()
    }

    init(result: Result<Success, Error>) {
        self.getResult = { result }
    }

    init(getResult: @escaping () -> Result<Success, Error>) {
        self.getResult = getResult
    }

    func value(context: Context) async throws -> Success {
        try getResult().get()
    }
}

struct TestPublisherAtom<Publisher: Combine.Publisher>: PublisherAtom {
    var makePublisher: () -> Publisher

    var key: UniqueKey {
        UniqueKey()
    }

    func publisher(context: Context) -> Publisher {
        makePublisher()
    }
}

struct TestAsyncSequenceAtom<Sequence: AsyncSequence>: AsyncSequenceAtom {
    var makeSequence: () -> Sequence

    var key: UniqueKey {
        UniqueKey()
    }

    func sequence(context: Context) -> Sequence {
        makeSequence()
    }
}
