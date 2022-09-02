import XCTest

@testable import Atoms

@MainActor
final class TaskAtomTests: XCTestCase {
    func testValue() async {
        let atom = TestTaskAtom(value: 0)
        let context = AtomTestContext()

        do {
            // Initial value
            let value = await context.watch(atom).value
            XCTAssertEqual(value, 0)
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

            let value1 = await context.watch(atom).value
            XCTAssertEqual(value1, 200)
        }

        do {
            // Override termination
            context.override(atom) { _ in Task { 300 } }

            let task = context.watch(atom)
            context.unwatch(atom)

            XCTAssertTrue(task.isCancelled)
        }
    }

    func testRefresh() async {
        var value = 0
        let atom = TestTaskAtom<Int> { value }
        let context = AtomTestContext()

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.watch(atom)

            let value0 = await context.refresh(atom).value
            XCTAssertEqual(value0, 0)
            XCTAssertEqual(updateCount, 1)

            value = 1

            let value1 = await context.refresh(atom).value
            XCTAssertEqual(value1, 1)
            XCTAssertEqual(updateCount, 2)
        }

        do {
            // Cancellation
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }

            let refreshTask0 = Task {
                await context.refresh(atom)
            }

            Task {
                refreshTask0.cancel()
            }

            let task = await refreshTask0.value

            XCTAssertTrue(task.isCancelled)
        }

        do {
            // Override
            context.override(atom) { _ in Task { 300 } }

            let value = await context.refresh(atom).value
            XCTAssertEqual(value, 300)
        }

        do {
            // Override cancellation

            context.override(atom) { _ in Task { 400 } }

            let refreshTask = Task {
                await context.refresh(atom)
            }

            Task {
                refreshTask.cancel()
            }

            let task = await refreshTask.value

            XCTAssertTrue(task.isCancelled)
        }
    }

    func testReleaseDependencies() async {
        struct DependencyAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: TaskAtom, Hashable {
            func value(context: Context) async -> Int {
                let dependency = context.watch(DependencyAtom())
                return dependency
            }
        }

        let context = AtomTestContext()

        let value0 = await context.watch(TestAtom()).value

        XCTAssertEqual(value0, 0)

        context[DependencyAtom()] = 100

        let value1 = await context.watch(TestAtom()).value

        // Dependencies should not be released until task value is returned.
        XCTAssertEqual(value1, 100)

        context.unwatch(TestAtom())

        let dependencyValue = context.read(DependencyAtom())

        XCTAssertEqual(dependencyValue, 0)
    }

    func testUpdated() async {
        var updatedTaskHashValues = [Int]()
        let atom = TestTaskAtom {
            0
        } onUpdated: { new, _ in
            updatedTaskHashValues.append(new.hashValue)
        }
        let context = AtomTestContext()

        let task0 = context.watch(atom)

        XCTAssertTrue(updatedTaskHashValues.isEmpty)

        context.reset(atom)

        let task1 = context.watch(atom)

        // Ensures that the transactions are done, othewise the store context access to the store which is already released.
        _ = await task0.value
        _ = await task1.value

        XCTAssertEqual(updatedTaskHashValues, [task1.hashValue])
    }
}
