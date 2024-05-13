import XCTest

@testable import Atoms

final class ThrowingTaskAtomTests: XCTestCase {
    @MainActor
    func test() async throws {
        var result = Result<Int, Error>.success(0)
        let atom = TestThrowingTaskAtom { result }
        let context = AtomTestContext()

        do {
            // Initial value
            let value = try await context.watch(atom).value
            XCTAssertEqual(value, 0)
        }

        do {
            // Error
            do {
                context.unwatch(atom)
                result = .failure(URLError(.badURL))

                _ = try await context.watch(atom).value

                XCTFail("Accessing to value should throw an error")
            }
            catch {
                XCTAssertEqual(error as? URLError, URLError(.badURL))
            }
        }

        do {
            // Termination
            let task = context.watch(atom)
            context.unwatch(atom)

            XCTAssertTrue(task.isCancelled)
        }

        do {
            // Override
            context.override(atom) { _ in Task { 200 } }

            let value = try await context.watch(atom).value
            XCTAssertEqual(value, 200)

            // Override termination

            context.override(atom) { _ in Task { 300 } }

            let task = context.watch(atom)
            context.unwatch(atom)

            XCTAssertTrue(task.isCancelled)
        }
    }

    @MainActor
    func testRefresh() async throws {
        var result = Result<Int, Error>.success(0)
        let atom = TestThrowingTaskAtom { result }
        let context = AtomTestContext()

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.watch(atom)

            let value0 = try await context.refresh(atom).value
            XCTAssertEqual(value0, 0)
            XCTAssertEqual(updateCount, 1)

            result = .success(1)

            let value1 = try await context.refresh(atom).value
            XCTAssertEqual(value1, 1)
            XCTAssertEqual(updateCount, 2)
        }

        do {
            // Cancellation
            let refreshTask = Task {
                await context.refresh(atom)
            }

            Task {
                refreshTask.cancel()
            }

            let task = await refreshTask.value

            XCTAssertTrue(task.isCancelled)
        }

        do {
            // Override
            context.override(atom) { _ in Task { 300 } }

            let value = try await context.refresh(atom).value
            XCTAssertEqual(value, 300)
        }

        do {
            // Override cancellation

            context.override(atom) { _ in Task { 400 } }

            let refreshTask1 = Task {
                await context.refresh(atom)
            }

            Task {
                refreshTask1.cancel()
            }

            let task1 = await refreshTask1.value

            XCTAssertTrue(task1.isCancelled)
        }
    }

    @MainActor
    func testReleaseDependencies() async throws {
        struct DependencyAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: ThrowingTaskAtom, Hashable {
            func value(context: Context) async throws -> Int {
                let dependency = context.watch(DependencyAtom())
                return dependency
            }
        }

        let context = AtomTestContext()

        let value0 = try await context.watch(TestAtom()).value

        XCTAssertEqual(value0, 0)

        context[DependencyAtom()] = 100

        let value1 = try await context.watch(TestAtom()).value

        // Dependencies should not be released until task value is returned.
        XCTAssertEqual(value1, 100)

        context.unwatch(TestAtom())

        let dependencyValue = context.read(DependencyAtom())

        XCTAssertEqual(dependencyValue, 0)
    }

    @MainActor
    func testEffect() {
        let effect = TestEffect()
        let atom = TestThrowingTaskAtom(effect: effect) { .success(0) }
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 0)
        XCTAssertEqual(effect.releasedCount, 0)

        context.reset(atom)
        context.reset(atom)
        context.reset(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 0)

        context.unwatch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 1)
    }
}
