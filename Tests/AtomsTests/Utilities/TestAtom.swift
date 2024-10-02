import Combine

@testable import Atoms

struct TestAtom<T: Hashable>: ValueAtom, Hashable, @unchecked Sendable {
    var value: T

    func value(context: Context) -> T {
        value
    }
}

struct TestValueAtom<T>: ValueAtom, @unchecked Sendable {
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

struct TestStateAtom<T>: StateAtom, @unchecked Sendable {
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

struct TestTaskAtom<T: Sendable>: TaskAtom, @unchecked Sendable {
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

struct TestThrowingTaskAtom<Success: Sendable>: ThrowingTaskAtom, @unchecked Sendable {
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

struct TestCustomRefreshableAtom<T: Sendable>: ValueAtom, Refreshable, @unchecked Sendable {
    var getValue: (Context) -> T
    var refresh: (CurrentContext) async -> T

    var key: UniqueKey {
        UniqueKey()
    }

    func value(context: Context) -> T {
        getValue(context)
    }

    func refresh(context: CurrentContext) async -> T {
        await refresh(context)
    }
}

struct TestCustomResettableAtom<T>: StateAtom, Resettable, @unchecked Sendable {
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

struct TestPublisherAtom<Publisher: Combine.Publisher>: PublisherAtom, @unchecked Sendable where Publisher.Output: Sendable {
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

struct TestAsyncSequenceAtom<Sequence: AsyncSequence>: AsyncSequenceAtom, @unchecked Sendable where Sequence.Element: Sendable {
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

struct TestObservableObjectAtom: ObservableObjectAtom, @unchecked Sendable {
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
