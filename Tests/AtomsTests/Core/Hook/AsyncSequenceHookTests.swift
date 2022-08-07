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

    func testUpdate() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        let hook = AsyncSequenceHook { _ in pipe.stream }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        do {
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        do {
            // Value
            pipe.continuation.yield(0)
            await context.waitUntilNextUpdate()

            XCTAssertEqual(context.watch(atom).value, 0)
        }

        do {
            // Failure
            pipe.continuation.finish(throwing: URLError(.badURL))
            await context.waitUntilNextUpdate()

            XCTAssertEqual(context.watch(atom).error as? URLError, URLError(.badURL))
        }

        do {
            // Yield value after finish
            pipe.continuation.yield(1)
            let didUpdate = await context.waitUntilNextUpdate(timeout: 1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Yield value after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.yield(0)
            let didUpdate = await context.waitUntilNextUpdate(timeout: 1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Yield error after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.finish(throwing: URLError(.badURL))
            let didUpdate = await context.waitUntilNextUpdate(timeout: 1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Override
            context.override(atom) { _ in .success(100) }

            XCTAssertEqual(context.watch(atom).value, 100)
        }
    }

    func testRefresh() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        let hook = AsyncSequenceHook { _ in pipe.stream }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        do {
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            pipe.reset()

            Task {
                pipe.continuation.yield(0)
                pipe.continuation.finish(throwing: nil)
            }

            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 0)
            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Cancellation
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            pipe.reset()

            let refreshTask = Task {
                await context.refresh(atom)
            }

            Task {
                pipe.continuation.yield(1)
                refreshTask.cancel()
            }

            let phase = await refreshTask.value

            XCTAssertEqual(phase.value, 1)
            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Override
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.override(atom) { _ in .success(200) }
            pipe.reset()

            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 200)
            XCTAssertEqual(updateCount, 1)
        }
    }
}
