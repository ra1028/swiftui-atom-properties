import XCTest

@testable import Atoms

@MainActor
final class ThrowingTaskHookTests: XCTestCase {
    func testMakeCoordinator() {
        let hook = ThrowingTaskHook { _ in 0 }
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.task)
    }

    func testValue() async throws {
        let hook = ThrowingTaskHook<Int> { _ in 0 }
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.task = Task { 100 }

        let value = try await hook.value(context: context).value

        XCTAssertEqual(value, 100)
    }

    func testUpdate() async throws {
        var makeValue: () throws -> Int = { 100 }
        let hook = ThrowingTaskHook { _ in try makeValue() }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        // Value

        let value0 = try await context.watch(atom).value
        XCTAssertEqual(value0, 100)

        // Error

        do {
            makeValue = { throw URLError(.badURL) }
            context.unwatch(atom)
            _ = try await context.watch(atom).value

            XCTFail("Accessing to value should throw an error")
        }
        catch {
            XCTAssertEqual(error as? URLError, URLError(.badURL))
        }

        // Termination

        let task0 = context.watch(atom)
        context.unwatch(atom)

        XCTAssertTrue(task0.isCancelled)

        // Override

        context.override(atom) { _ in Task { 200 } }

        let value1 = try await context.watch(atom).value
        XCTAssertEqual(value1, 200)

        // Override termination

        context.override(atom) { _ in Task { 300 } }

        let task1 = context.watch(atom)
        context.unwatch(atom)

        XCTAssertTrue(task1.isCancelled)
    }

    func testRefresh() async throws {
        var value = 100
        let hook = ThrowingTaskHook { _ in value }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = { updateCount += 1 }

        // Refresh

        context.watch(atom)

        let value0 = try await context.refresh(atom).value
        XCTAssertEqual(value0, 100)
        XCTAssertEqual(updateCount, 1)

        value = 200

        let value1 = try await context.refresh(atom).value
        XCTAssertEqual(value1, 200)
        XCTAssertEqual(updateCount, 2)

        // Cancellation

        let refreshTask0 = Task {
            await context.refresh(atom)
        }

        Task {
            refreshTask0.cancel()
        }

        let task0 = await refreshTask0.value

        XCTAssertTrue(task0.isCancelled)

        // Override

        context.override(atom) { _ in Task { 300 } }

        let value2 = try await context.refresh(atom).value
        XCTAssertEqual(value2, 300)

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
