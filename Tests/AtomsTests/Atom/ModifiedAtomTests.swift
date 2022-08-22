import XCTest

@testable import Atoms

@MainActor
final class ModifiedAtomTests: XCTestCase {
    func testKey() {
        let base = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let atom = ModifiedAtom(atom: base, modifier: modifier)

        XCTAssertEqual(atom.key, atom.key)
        XCTAssertEqual(atom.key.hashValue, atom.key.hashValue)
        XCTAssertNotEqual(AnyHashable(atom.key), AnyHashable(modifier.key))
        XCTAssertNotEqual(AnyHashable(atom.key).hashValue, AnyHashable(modifier.key).hashValue)
        XCTAssertNotEqual(AnyHashable(atom.key), AnyHashable(base.key))
        XCTAssertNotEqual(AnyHashable(atom.key).hashValue, AnyHashable(base.key).hashValue)
    }

    func testValue() async {
        let base = TestStateAtom(defaultValue: "test")
        let modifier = SelectModifier<String, Int>(keyPath: \.count)
        let atom = ModifiedAtom(atom: base, modifier: modifier)
        let context = AtomTestContext()

        do {
            // Initial value
            XCTAssertEqual(context.watch(atom), 4)
        }

        do {
            // Update
            Task {
                context[base] = "testtest"
            }

            await context.waitUntilNextUpdate()
            XCTAssertEqual(context.watch(atom), 8)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in
                100
            }

            XCTAssertEqual(context.watch(atom), 100)
        }
    }
}
