import XCTest

@testable import Atoms

final class AsyncSequenceAtomTests: XCTestCase {
    @MainActor
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
            await context.wait(for: atom, until: \.isSuccess)

            XCTAssertEqual(context.watch(atom).value, 0)
        }

        do {
            // Failure
            pipe.continuation.finish(throwing: URLError(.badURL))
            await context.wait(for: atom, until: \.isFailure)

            XCTAssertEqual(context.watch(atom).error as? URLError, URLError(.badURL))
        }

        do {
            // Yield value after finish
            pipe.continuation.yield(1)
            let didUpdate = await context.waitForUpdate(timeout: 0.1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Yield value after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.yield(0)
            let didUpdate = await context.waitForUpdate(timeout: 0.1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Yield error after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.finish(throwing: URLError(.badURL))
            let didUpdate = await context.waitForUpdate(timeout: 0.1)

            XCTAssertFalse(didUpdate)
        }

        do {
            // Override
            context.override(atom) { _ in .success(100) }

            XCTAssertEqual(context.watch(atom).value, 100)
        }
    }

    @MainActor
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

            XCTAssertTrue(phase.isSuspending)
            XCTAssertEqual(updateCount, 0)
        }

        do {
            // Override
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.override(atom) { _ in .success(200) }
            pipe.reset()

            context.unwatch(atom)
            XCTAssertEqual(context.watch(atom).value, 200)

            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 200)
            XCTAssertEqual(updateCount, 1)
        }
    }

    @MainActor
    func testEffect() async {
        var state = EffectState()
        let effect = TestEffect(
            onInitialize: { state.initialized += 1 },
            onUpdate: { state.updated += 1 },
            onRelease: { state.released += 1 }
        )
        let pipe = AsyncThrowingStreamPipe<Int>()
        let atom = TestAsyncSequenceAtom(effect: effect) {
            pipe.stream
        }
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 0,
                released: 0
            )
        )

        pipe.continuation.yield(0)
        await context.waitForUpdate()

        pipe.continuation.yield(1)
        await context.waitForUpdate()

        pipe.continuation.yield(2)
        await context.waitForUpdate()

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 3,
                released: 0
            )
        )

        context.unwatch(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 3,
                released: 1
            )
        )
    }
}
