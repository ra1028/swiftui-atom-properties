import Combine

@testable import Atoms

final class Object {}

struct UniqueKey: Hashable {}

struct Pair<T: Equatable>: Equatable {
    let first: T
    let second: T
}

final class AsyncThrowingStreamPipe<Element> {
    private(set) var stream: AsyncThrowingStream<Element, Error>
    private(set) var continuation: AsyncThrowingStream<Element, Error>.Continuation!

    init() {
        (stream, continuation) = Self.pipe()
    }

    func reset() {
        (stream, continuation) = Self.pipe()
    }

    private static func pipe() -> (
        AsyncThrowingStream<Element, Error>,
        AsyncThrowingStream<Element, Error>.Continuation
    ) {
        var continuation: AsyncThrowingStream<Element, Error>.Continuation!
        let stream = AsyncThrowingStream { continuation = $0 }
        return (stream, continuation)
    }
}

final class ResettableSubject<Output, Failure: Error>: Publisher, Subject {
    private var internalSubject = PassthroughSubject<Output, Failure>()

    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
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

extension SubscriptionContainer {
    var wrapper: Wrapper {
        let location = SourceLocation(fileID: #fileID, line: #line)
        return wrapper(location: location)
    }
}

extension AtomCache: Equatable where Node: Equatable, Node.Loader.Value: Equatable {
    // NB: Synthesized Equatable conformance doesn't work well in Xcode 14.0.1.
    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.atom == rhs.atom && lhs.value == rhs.value
    }
}
