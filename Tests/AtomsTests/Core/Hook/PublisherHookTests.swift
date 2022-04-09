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

    func testUpdate() {
        let subject = TestSubject<Int, URLError>()
        let hook = PublisherHook { _ in subject }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Initially suspending") { _ in
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        XCTContext.runActivity(named: "Value") { _ in
            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill
            subject.send(0)

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom), .success(0))
        }

        XCTContext.runActivity(named: "Error") { _ in
            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill
            subject.send(completion: .failure(URLError(.badURL)))

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom), .failure(URLError(.badURL)))
        }

        XCTContext.runActivity(named: "Value after completion") { _ in
            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill
            subject.send(1)

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom), .failure(URLError(.badURL)))
        }

        XCTContext.runActivity(named: "Value after termination") { _ in
            context.unwatch(atom)
            subject.reset()
            context.watch(atom)
            context.unwatch(atom)

            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill
            subject.send(0)

            wait(for: [expectation], timeout: 1)
        }

        XCTContext.runActivity(named: "Error after termination") { _ in
            context.unwatch(atom)
            subject.reset()
            context.watch(atom)
            context.unwatch(atom)

            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill
            subject.send(completion: .failure(URLError(.badURL)))

            wait(for: [expectation], timeout: 1)
        }

        XCTContext.runActivity(named: "Override") { _ in
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

        // Refresh

        XCTAssertTrue(context.watch(atom).isSuspending)

        Task {
            subject.send(0)
            subject.send(completion: .finished)
        }

        subject.reset()
        let phase0 = await context.refresh(atom)

        XCTAssertEqual(phase0.value, 0)
        XCTAssertEqual(updateCount, 1)

        // Cancellation

        let refreshTask = Task {
            await context.refresh(atom)
        }

        Task {
            subject.send(1)
            refreshTask.cancel()
        }

        subject.reset()
        let phase1 = await refreshTask.value

        XCTAssertEqual(phase1, .success(1))
        XCTAssertEqual(updateCount, 2)

        // Override

        context.override(atom) { _ in .success(200) }

        subject.reset()
        let phase2 = await context.refresh(atom)

        XCTAssertEqual(phase2.value, 200)
        XCTAssertEqual(updateCount, 3)
    }
}
