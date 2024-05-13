import XCTest

@testable import Atoms

final class StateAtomTests: XCTestCase {
    @MainActor
    func testValue() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        do {
            // Value
            XCTAssertEqual(context.watch(atom), 0)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in 200 }

            XCTAssertEqual(context.watch(atom), 200)
        }
    }

    @MainActor
    func testSet() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
    }

    @MainActor
    func testSetOverride() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.override(atom) { _ in 200 }

        XCTAssertEqual(context.watch(atom), 200)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
    }

    @MainActor
    func testDependency() async {
        struct Dependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                context.watch(Dependency1Atom())
            }
        }

        let context = AtomTestContext()

        let value0 = context.watch(TestAtom())
        XCTAssertEqual(value0, 0)

        context[TestAtom()] = 1

        let value1 = context.watch(TestAtom())
        XCTAssertEqual(value1, 1)

        // Updated by the depenency update.

        Task {
            context[Dependency1Atom()] = 0
        }

        await context.waitForUpdate()

        let value2 = context.watch(TestAtom())
        XCTAssertEqual(value2, 0)
    }

    @MainActor
    func testEffect() {
        let effect = TestEffect()
        let atom = TestStateAtom(defaultValue: 0, effect: effect)
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 0)
        XCTAssertEqual(effect.releasedCount, 0)

        context.set(1, for: atom)
        context.set(2, for: atom)
        context.set(3, for: atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 0)

        context.unwatch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 1)
    }
}
