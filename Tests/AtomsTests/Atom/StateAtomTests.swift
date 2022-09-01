import XCTest

@testable import Atoms

@MainActor
final class StateAtomTests: XCTestCase {
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

    func testSet() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
    }

    func testSetOverride() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.override(atom) { _ in 200 }

        XCTAssertEqual(context.watch(atom), 200)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
    }

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

        await context.waitUntilNextUpdate()

        let value2 = context.watch(TestAtom())
        XCTAssertEqual(value2, 0)
    }
}
