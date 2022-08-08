import Atoms
import Combine

struct TestAtom<Key: Hashable, State: AtomState>: Atom {
    var key: Key
    var state: State

    func makeState() -> State {
        state
    }
}

struct TestValueAtom<T: Hashable>: ValueAtom, Hashable {
    var value: T

    func value(context: Context) -> T {
        value
    }
}

struct TestStateAtom<T: Hashable>: StateAtom, Hashable {
    var defaultValue: T
    var willSet: ((T, T) -> Void)?
    var didSet: ((T, T) -> Void)?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.defaultValue == rhs.defaultValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(defaultValue)
    }

    func defaultValue(context: Context) -> T {
        defaultValue
    }

    func willSet(newValue: T, oldValue: T, context: Context) {
        willSet?(newValue, oldValue)
    }

    func didSet(newValue: T, oldValue: T, context: Context) {
        didSet?(newValue, oldValue)
    }
}

struct TestTaskAtom<T>: TaskAtom, Hashable {
    var getValue: () -> T

    init(value: T) {
        self.getValue = { value }
    }

    init(getValue: @escaping () -> T) {
        self.getValue = getValue
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {}

    func value(context: Context) async -> T {
        getValue()
    }
}

struct TestThrowingTaskAtom<Success>: ThrowingTaskAtom, Hashable {
    var getResult: () -> Result<Success, Error>

    init(result: Result<Success, Error>) {
        self.getResult = { result }
    }

    init(getResult: @escaping () -> Result<Success, Error>) {
        self.getResult = getResult
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {}

    func value(context: Context) async throws -> Success {
        try getResult().get()
    }
}

struct TestPublisherAtom<Publisher: Combine.Publisher>: PublisherAtom, Hashable {
    var makePublisher: () -> Publisher

    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {}

    func publisher(context: Context) -> Publisher {
        makePublisher()
    }
}

struct TestAsyncSequenceAtom<Sequence: AsyncSequence>: AsyncSequenceAtom, Hashable {
    var makeSequence: () -> Sequence

    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {}

    func sequence(context: Context) -> Sequence {
        makeSequence()
    }
}
