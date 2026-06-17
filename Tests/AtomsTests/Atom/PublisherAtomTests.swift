import Combine
import Foundation
import Testing

@testable import Atoms

struct PublisherAtomTests {
    @MainActor
    @Test
    func testValue() async {
        let subject = ResettableSubject<Int, URLError>()
        let atom = TestPublisherAtom { subject }
        let context = AtomTestContext()

        do {
            // Initial value
            let phase = context.watch(atom)
            #expect(phase == .suspending)
        }

        do {
            // Value
            subject.send(0)

            await context.wait(for: atom, until: \.isSuccess)
            #expect(context.watch(atom) == .success(0))
        }

        do {
            // Error
            subject.send(completion: .failure(URLError(.badURL)))

            await context.wait(for: atom, until: \.isFailure)
            #expect(context.watch(atom) == .failure(URLError(.badURL)))
        }

        do {
            // Send value after completion
            subject.send(1)

            let didUpdate = await context.waitForUpdate(timeout: 0.1)
            #expect(!(didUpdate))
        }

        do {
            // Send value after termination
            context.unwatch(atom)
            subject.send(0)

            let didUpdate = await context.waitForUpdate(timeout: 0.1)
            #expect(!(didUpdate))
        }

        do {
            // Send error after termination
            context.unwatch(atom)
            subject.send(completion: .failure(URLError(.badURL)))

            let didUpdate = await context.waitForUpdate(timeout: 0.1)
            #expect(!(didUpdate))
        }

        do {
            // Override
            context.override(atom) { _ in .success(100) }

            #expect(context.watch(atom) == .success(100))
        }
    }

    @MainActor
    @Test
    func testRefresh() async {
        let subject = ResettableSubject<Int, URLError>()
        let atom = TestPublisherAtom { subject }
        let context = AtomTestContext()

        do {
            #expect(context.watch(atom).isSuspending)
        }

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            subject.reset()

            Task {
                subject.send(0)
                subject.send(completion: .finished)
            }

            let phase = await context.refresh(atom)

            #expect(phase.value == 0)
            #expect(updateCount == 1)
        }

        do {
            // Cancellation
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            subject.reset()

            let refreshTask = Task {
                await context.refresh(atom)
            }

            Task {
                subject.send(1)
                refreshTask.cancel()
            }

            let phase = await refreshTask.value

            #expect(phase == .suspending)
            #expect(updateCount == 0)
        }

        do {
            // Override
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.override(atom) { _ in .success(200) }
            subject.reset()

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
        let subject = ResettableSubject<Int, URLError>()
        let atom = TestPublisherAtom(effect: effect) { subject }
        let context = AtomTestContext()

        context.watch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        subject.send(0)
        await context.waitForUpdate()

        subject.send(1)
        await context.waitForUpdate()

        subject.send(2)
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
