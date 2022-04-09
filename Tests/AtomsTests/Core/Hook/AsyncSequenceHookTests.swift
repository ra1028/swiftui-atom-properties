import XCTest

@testable import Atoms

@MainActor
final class AsyncSequenceHookTests: XCTestCase {
    final class AsyncThrowingStreamPipe<Element> {
        var stream: AsyncThrowingStream<Element, Error>
        var continuation: AsyncThrowingStream<Element, Error>.Continuation!

        init() {
            (stream, continuation) = Self.pipe()
        }

        func reset() {
            (stream, continuation) = Self.pipe()
        }

        static func pipe() -> (
            AsyncThrowingStream<Element, Error>,
            AsyncThrowingStream<Element, Error>.Continuation
        ) {
            var continuation: AsyncThrowingStream<Element, Error>.Continuation!
            let stream = AsyncThrowingStream { continuation = $0 }
            return (stream, continuation)
        }
    }

    func testMakeCoordinator() {
        let hook = AsyncSequenceHook { _ in
            AsyncStream<Int> { _ in }
        }
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.phase)
    }

    func testValue() {
        let hook = AsyncSequenceHook { _ in
            AsyncThrowingStream<Int, Error> { _ in }
        }
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
        let pipe = AsyncThrowingStreamPipe<Int>()
        let hook = AsyncSequenceHook { _ in pipe.stream }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Initially suspending") { _ in
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        XCTContext.runActivity(named: "Value") { _ in
            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill
            pipe.continuation.yield(0)

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom).value, 0)
        }

        XCTContext.runActivity(named: "Error") { _ in
            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill
            pipe.continuation.finish(throwing: URLError(.badURL))

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom).error as? URLError, URLError(.badURL))
        }

        XCTContext.runActivity(named: "Value after finished") { _ in
            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill
            pipe.continuation.yield(1)

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom).error as? URLError, URLError(.badURL))
        }

        XCTContext.runActivity(named: "Value after termination") { _ in
            context.unwatch(atom)
            pipe.reset()
            context.watch(atom)
            context.unwatch(atom)

            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill
            pipe.continuation.yield(0)

            wait(for: [expectation], timeout: 1)
        }

        XCTContext.runActivity(named: "Error after termination") { _ in
            context.unwatch(atom)
            pipe.reset()
            context.watch(atom)
            context.unwatch(atom)

            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill
            pipe.continuation.finish(throwing: URLError(.badURL))

            wait(for: [expectation], timeout: 1)
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.override(atom) { _ in .success(100) }

            XCTAssertEqual(context.watch(atom).value, 100)
        }
    }

    func testRefresh() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        let hook = AsyncSequenceHook { _ in pipe.stream }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = { updateCount += 1 }

        // Refresh

        XCTAssertTrue(context.watch(atom).isSuspending)

        Task {
            pipe.continuation.yield(0)
            pipe.continuation.finish(throwing: nil)
        }

        pipe.reset()
        let phase0 = await context.refresh(atom)

        XCTAssertEqual(phase0.value, 0)
        XCTAssertEqual(updateCount, 1)

        // Cancellation

        let refreshTask = Task {
            await context.refresh(atom)
        }

        Task {
            pipe.continuation.yield(1)
            refreshTask.cancel()
        }

        pipe.reset()
        let phase1 = await refreshTask.value

        XCTAssertEqual(phase1.value, 1)
        XCTAssertEqual(updateCount, 2)

        // Override

        context.override(atom) { _ in .success(200) }

        pipe.reset()
        let phase2 = await context.refresh(atom)

        XCTAssertEqual(phase2.value, 200)
        XCTAssertEqual(updateCount, 3)
    }
}
