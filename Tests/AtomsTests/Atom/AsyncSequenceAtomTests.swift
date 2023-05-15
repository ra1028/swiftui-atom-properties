import XCTest

@testable import Atoms

@MainActor
final class AsyncSequenceAtomTests: XCTestCase {
    func testValue() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        let atom = TestAsyncSequenceAtom { pipe.stream }
        let context = AtomTestContext()

        do {
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        do {
            // Value
            pipe.continuation.yield(0)
            await context.waitForUpdate()

            XCTAssertEqual(context.watch(atom).value, 0)
        }

        do {
            // Failure
            pipe.continuation.finish(throwing: URLError(.badURL))
            await context.waitForUpdate()

            XCTAssertEqual(context.watch(atom).error as? URLError, URLError(.badURL))
        }

        do {
            // Yield value after finish
            pipe.continuation.yield(1)
            let didUpdate = await context.waitForUpdate(timeout: 1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Yield value after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.yield(0)
            let didUpdate = await context.waitForUpdate(timeout: 1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Yield error after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.finish(throwing: URLError(.badURL))
            let didUpdate = await context.waitForUpdate(timeout: 1)

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
        let atom = TestAsyncSequenceAtom { pipe.stream }
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

    func testUpdated() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        var updatedValues = [Pair<Int?>]()
        let atom = TestAsyncSequenceAtom {
            pipe.stream
        } onUpdated: { new, old in
            let values = Pair(first: new.value, second: old.value)
            updatedValues.append(values)
        }
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertTrue(updatedValues.isEmpty)

        pipe.continuation.yield(0)
        await context.waitForUpdate()

        pipe.continuation.yield(1)
        await context.waitForUpdate()

        pipe.continuation.yield(2)
        await context.waitForUpdate()

        XCTAssertEqual(
            updatedValues,
            [
                Pair(first: 0, second: nil),
                Pair(first: 1, second: 0),
                Pair(first: 2, second: 1),
            ]
        )
    }
}
