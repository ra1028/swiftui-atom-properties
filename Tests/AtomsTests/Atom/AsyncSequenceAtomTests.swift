import Foundation
import Testing

@testable import Atoms

struct AsyncSequenceAtomTests {
    @MainActor
    @Test
    func testValue() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        let atom = TestAsyncSequenceAtom { pipe.stream }
        let context = AtomTestContext()

        do {
            #expect(context.watch(atom).isSuspending)
        }

        do {
            // Value
            pipe.continuation.yield(0)
            await context.wait(for: atom, until: \.isSuccess)

            #expect(context.watch(atom).value == 0)
        }

        do {
            // Failure
            pipe.continuation.finish(throwing: URLError(.badURL))
            await context.wait(for: atom, until: \.isFailure)

            #expect(context.watch(atom).error as? URLError == URLError(.badURL))
        }

        do {
            // Yield value after finish
            pipe.continuation.yield(1)
            let didUpdate = await context.waitForUpdate(timeout: 0.1)

            #expect(!(didUpdate))
        }

        do {
            // Yield value after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.yield(0)
            let didUpdate = await context.waitForUpdate(timeout: 0.1)

            #expect(!(didUpdate))
        }

        do {
            // Yield error after termination
            pipe.reset()
            context.unwatch(atom)

            pipe.continuation.finish(throwing: URLError(.badURL))
            let didUpdate = await context.waitForUpdate(timeout: 0.1)

            #expect(!(didUpdate))
        }

        do {
            // Override
            context.override(atom) { _ in .success(100) }

            #expect(context.watch(atom).value == 100)
        }
    }

    @MainActor
    @Test
    func testRefresh() async {
        let pipe = AsyncThrowingStreamPipe<Int>()
        let atom = TestAsyncSequenceAtom { pipe.stream }
        let context = AtomTestContext()

        do {
            #expect(context.watch(atom).isSuspending)
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

            #expect(phase.value == 0)
            #expect(updateCount == 1)
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

            #expect(phase.isSuspending)
            #expect(updateCount == 0)
        }

        do {
            // Override
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.override(atom) { _ in .success(200) }
            pipe.reset()

            context.unwatch(atom)
            #expect(context.watch(atom).value == 200)

            let phase = await context.refresh(atom)

            #expect(phase.value == 200)
            #expect(updateCount == 1)
        }
    }

    @MainActor
    @Test
    func testEffect() async {
        let effect = TestEffect()
        let pipe = AsyncThrowingStreamPipe<Int>()
        let atom = TestAsyncSequenceAtom(effect: effect) { pipe.stream }
        let context = AtomTestContext()

        context.watch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        pipe.continuation.yield(0)
        await context.waitForUpdate()

        pipe.continuation.yield(1)
        await context.waitForUpdate()

        pipe.continuation.yield(2)
        await context.waitForUpdate()

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 0)

        context.unwatch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 1)
    }
}
