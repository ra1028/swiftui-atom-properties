import Combine
import XCTest

@testable import Atoms

@MainActor
final class PublisherAtomTests: XCTestCase {
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

            XCTAssertEqual(phase, .success(1))
            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Override
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.override(atom) { _ in .success(200) }

            subject.reset()
            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 200)
            XCTAssertEqual(updateCount, 1)
        }
    }

    func testUpdated() async {
        let subject = ResettableSubject<Int, URLError>()
        var updatedValues = [Pair<Int?>]()
        let atom = TestPublisherAtom {
            subject
        } onUpdated: { new, old in
            let values = Pair(first: new.value, second: old.value)
            updatedValues.append(values)
        }
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertTrue(updatedValues.isEmpty)

        subject.send(0)
        await context.waitUntilNextUpdate()

        subject.send(1)
        await context.waitUntilNextUpdate()

        subject.send(2)
        await context.waitUntilNextUpdate()

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
