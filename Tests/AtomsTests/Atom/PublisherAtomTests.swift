import Combine
import XCTest

@testable import Atoms

final class PublisherAtomTests: XCTestCase {
    @MainActor
    func testValue() async {
        let subject = ResettableSubject<Int, URLError>()
        let atom = TestPublisherAtom { subject }
        let context = AtomTestContext()

        do {
            // Initial value
            let phase = context.watch(atom)
            XCTAssertEqual(phase, .suspending)
        }

        do {
            // Value
            subject.send(0)

            await context.wait(for: atom, until: \.isSuccess)
            XCTAssertEqual(context.watch(atom), .success(0))
        }

        do {
            // Error
            subject.send(completion: .failure(URLError(.badURL)))

            await context.wait(for: atom, until: \.isFailure)
            XCTAssertEqual(context.watch(atom), .failure(URLError(.badURL)))
        }

        do {
            // Send value after completion
            subject.send(1)

            let didUpdate = await context.waitForUpdate(timeout: 0.1)
            XCTAssertFalse(didUpdate)
        }

        do {
            // Send value after termination
            context.unwatch(atom)
            subject.send(0)

            let didUpdate = await context.waitForUpdate(timeout: 0.1)
            XCTAssertFalse(didUpdate)
        }

        do {
            // Send error after termination
            context.unwatch(atom)
            subject.send(completion: .failure(URLError(.badURL)))

            let didUpdate = await context.waitForUpdate(timeout: 0.1)
            XCTAssertFalse(didUpdate)
        }

        do {
            // Override
            context.override(atom) { _ in .success(100) }

            XCTAssertEqual(context.watch(atom), .success(100))
        }
    }

    @MainActor
    func testRefresh() async {
        let subject = ResettableSubject<Int, URLError>()
        let atom = TestPublisherAtom { subject }
        let context = AtomTestContext()

        do {
            XCTAssertTrue(context.watch(atom).isSuspending)
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

            XCTAssertEqual(phase.value, 0)
            XCTAssertEqual(updateCount, 1)
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

            XCTAssertEqual(phase, .suspending)
            XCTAssertEqual(updateCount, 0)
        }

        do {
            // Override
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.override(atom) { _ in .success(200) }
            subject.reset()

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
        let subject = ResettableSubject<Int, URLError>()

        let atom = TestPublisherAtom(effect: effect) {
            subject
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

        subject.send(0)
        await context.waitForUpdate()

        subject.send(1)
        await context.waitForUpdate()

        subject.send(2)
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
