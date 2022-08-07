import Combine
import XCTest

@testable import Atoms

@MainActor
final class PublisherHookTests: XCTestCase {
    final class TestSubject<Output, Failure: Error>: Publisher, Subject {
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

        func send(subscription: Subscription) {
            internalSubject.send(subscription: subscription)
        }

        func reset() {
            internalSubject = PassthroughSubject()
        }
    }

    func testMakeCoordinator() {
        let hook = PublisherHook { _ in Just(0) }
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.phase)
    }

    func testValue() {
        let hook = PublisherHook { _ in Just(0) }
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.phase = .success(100)

        XCTAssertEqual(hook.value(context: context).value, 100)
    }

    func testUpdate() async {
        let subject = TestSubject<Int, URLError>()
        let hook = PublisherHook { _ in subject }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        do {
            // Initially suspending
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        do {
            // Value
            subject.send(0)

            await context.waitUntilNextUpdate()
            XCTAssertEqual(context.watch(atom), .success(0))
        }

        do {
            // Error
            subject.send(completion: .failure(URLError(.badURL)))

            await context.waitUntilNextUpdate()
            XCTAssertEqual(context.watch(atom), .failure(URLError(.badURL)))
        }

        do {
            // Send value after completion
            subject.send(1)

            let didUpdate = await context.waitUntilNextUpdate(timeout: 1)
            XCTAssertFalse(didUpdate)
        }

        do {
            // Send value after termination
            context.unwatch(atom)
            subject.send(0)

            let didUpdate = await context.waitUntilNextUpdate(timeout: 1)
            XCTAssertFalse(didUpdate)
        }

        do {
            // Send error after termination
            context.unwatch(atom)
            subject.send(completion: .failure(URLError(.badURL)))

            let didUpdate = await context.waitUntilNextUpdate(timeout: 1)
            XCTAssertFalse(didUpdate)
        }

        do {
            // Override
            context.override(atom) { _ in .success(100) }

            XCTAssertEqual(context.watch(atom), .success(100))
        }
    }

    func testRefresh() async {
        let subject = TestSubject<Int, URLError>()
        let hook = PublisherHook { _ in subject }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = { updateCount += 1 }

        do {
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        do {
            // Refresh
            subject.reset()

            Task {
                subject.send(0)
                subject.send(completion: .finished)
            }

            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 0)
            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Cancellation
            subject.reset()

            let refreshTask = Task {
                await context.refresh(atom)
            }

            Task {
                subject.send(1)
                refreshTask.cancel()
            }

            let phase = await refreshTask.value

            XCTAssertEqual(phase, .success(1))
            XCTAssertEqual(updateCount, 2)
        }

        do {
            // Override
            context.override(atom) { _ in .success(200) }

            subject.reset()
            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 200)
            XCTAssertEqual(updateCount, 3)
        }
    }
}
