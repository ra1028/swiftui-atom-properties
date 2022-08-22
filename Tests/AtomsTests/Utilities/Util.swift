import Combine

@testable import Atoms

struct UniqueKey: Hashable {}
final class Object {}

final class TestObserver: AtomObserver {
    var assignedAtomKeys = [AtomKey]()
    var unassignedAtomKeys = [AtomKey]()
    var changedAtomKeys = [AtomKey]()

    func atomAssigned<Node: Atom>(atom: Node) {
        assignedAtomKeys.append(AtomKey(atom))
    }

    func atomUnassigned<Node: Atom>(atom: Node) {
        unassignedAtomKeys.append(AtomKey(atom))
    }

    func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
        changedAtomKeys.append(AtomKey(snapshot.atom))
    }
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
