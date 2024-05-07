import Combine

@testable import Atoms

struct TestAtom<T: Hashable>: ValueAtom, Hashable {
    var value: T

    func value(context: Context) -> T {
        value
    }
}

struct TestValueAtom<T>: ValueAtom {
    var value: T
    var effect: TestEffect?

    var key: UniqueKey {
        UniqueKey()
    }

    func value(context: Context) -> T {
        value
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}

struct TestStateAtom<T>: StateAtom {
    var defaultValue: T
    var effect: TestEffect?

    var key: UniqueKey {
        UniqueKey()
    }

    func defaultValue(context: Context) -> T {
        defaultValue
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}

struct TestTaskAtom<T: Sendable>: TaskAtom {
    var effect: TestEffect?
    var getValue: () -> T

    var key: UniqueKey {
        UniqueKey()
    }

    func value(context: Context) async -> T {
        getValue()
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}

struct TestThrowingTaskAtom<Success: Sendable>: ThrowingTaskAtom {
    var effect: TestEffect?
    var getResult: () -> Result<Success, Error>

    var key: UniqueKey {
        UniqueKey()
    }

    func value(context: Context) async throws -> Success {
        try getResult().get()
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}

struct TestCustomRefreshableAtom<Publisher: Combine.Publisher>: PublisherAtom, Refreshable {
    var makePublisher: () -> Publisher
    var refresh: () -> AsyncPhase<Publisher.Output, Publisher.Failure>

    var key: UniqueKey {
        UniqueKey()
    }

    func publisher(context: Context) -> Publisher {
        makePublisher()
    }

    func refresh(context: CurrentContext) async -> AsyncPhase<Publisher.Output, Publisher.Failure> {
        refresh()
    }
}

struct TestCustomResettableAtom<T>: StateAtom, Resettable {
    var defaultValue: (Context) -> T
    var reset: (CurrentContext) -> Void

    var key: UniqueKey {
        UniqueKey()
    }

    func defaultValue(context: Context) -> T {
        defaultValue(context)
    }

    func reset(context: CurrentContext) {
        reset(context)
    }
}

struct TestPublisherAtom<Publisher: Combine.Publisher>: PublisherAtom {
    var effect: TestEffect?
    var makePublisher: () -> Publisher

    var key: UniqueKey {
        UniqueKey()
    }

    func publisher(context: Context) -> Publisher {
        makePublisher()
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}

struct TestAsyncSequenceAtom<Sequence: AsyncSequence>: AsyncSequenceAtom {
    var effect: TestEffect?
    var makeSequence: () -> Sequence

    var key: UniqueKey {
        UniqueKey()
    }

    func sequence(context: Context) -> Sequence {
        makeSequence()
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}

struct TestObservableObjectAtom: ObservableObjectAtom {
    var effect: TestEffect?

    var key: UniqueKey {
        UniqueKey()
    }

    func object(context: Context) -> TestObservableObject {
        TestObservableObject()
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        effect ?? TestEffect()
    }
}
