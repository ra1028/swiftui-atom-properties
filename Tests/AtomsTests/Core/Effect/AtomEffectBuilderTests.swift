import XCTest

@testable import Atoms

final class AtomEffectBuilderTests: XCTestCase {
    @MainActor
    func testSingleBlock() {
        let expected = TestEffect()

        @AtomEffectBuilder
        func build() -> some AtomEffect {
            expected
        }

        let effect = build()
        effect.callAll()

        XCTAssertEqual(expected.initializingCount, 1)
        XCTAssertEqual(expected.initializedCount, 1)
        XCTAssertEqual(expected.updatedCount, 1)
        XCTAssertEqual(expected.releasedCount, 1)
    }

    @MainActor
    func testMultipleBlock() {
        let expected0 = TestEffect()
        let expected1 = TestEffect()
        let expected2 = TestEffect()

        @AtomEffectBuilder
        func build() -> some AtomEffect {
            expected0
            expected1
            expected2
        }

        let effect = build()
        effect.callAll()

        for expected in [expected0, expected1, expected2] {
            XCTAssertEqual(expected.initializingCount, 1)
            XCTAssertEqual(expected.initializedCount, 1)
            XCTAssertEqual(expected.updatedCount, 1)
            XCTAssertEqual(expected.releasedCount, 1)
        }
    }

    @MainActor
    func testIf() {
        let expected = TestEffect()
        var condition = true

        @AtomEffectBuilder
        func build() -> some AtomEffect {
            if condition {
                expected
            }
        }

        let effectTrue = build()
        effectTrue.callAll()

        XCTAssertEqual(expected.initializingCount, 1)
        XCTAssertEqual(expected.initializedCount, 1)
        XCTAssertEqual(expected.updatedCount, 1)
        XCTAssertEqual(expected.releasedCount, 1)

        condition = false
        let effectFalse = build()
        effectFalse.callAll()

        XCTAssertEqual(expected.initializingCount, 1)
        XCTAssertEqual(expected.initializedCount, 1)
        XCTAssertEqual(expected.updatedCount, 1)
        XCTAssertEqual(expected.releasedCount, 1)
    }

    @MainActor
    func testEither() {
        let expectedTrue = TestEffect()
        let expectedFalse = TestEffect()
        var condition = true

        @AtomEffectBuilder
        func build() -> some AtomEffect {
            if condition {
                expectedTrue
            }
            else {
                expectedFalse
            }
        }

        let effectTrue = build()
        effectTrue.callAll()

        XCTAssertEqual(expectedTrue.initializingCount, 1)
        XCTAssertEqual(expectedTrue.initializedCount, 1)
        XCTAssertEqual(expectedTrue.updatedCount, 1)
        XCTAssertEqual(expectedTrue.releasedCount, 1)
        XCTAssertEqual(expectedFalse.initializingCount, 0)
        XCTAssertEqual(expectedFalse.initializedCount, 0)
        XCTAssertEqual(expectedFalse.updatedCount, 0)
        XCTAssertEqual(expectedFalse.releasedCount, 0)

        condition = false
        let effectFalse = build()
        effectFalse.callAll()

        for expected in [expectedTrue, expectedFalse] {
            XCTAssertEqual(expected.initializingCount, 1)
            XCTAssertEqual(expected.initializedCount, 1)
            XCTAssertEqual(expected.updatedCount, 1)
            XCTAssertEqual(expected.releasedCount, 1)
        }
    }

    @MainActor
    func testLimitedAvailability() {
        let expected = TestEffect()

        @AtomEffectBuilder
        func buildTrue() -> some AtomEffect {
            if #available(iOS 1, *) {
                expected
            }
        }

        @AtomEffectBuilder
        func buildFalse() -> some AtomEffect {
            if #unavailable(iOS 1) {
                expected
            }
        }

        let effectTrue = buildTrue()
        effectTrue.callAll()

        XCTAssertEqual(expected.initializingCount, 1)
        XCTAssertEqual(expected.initializedCount, 1)
        XCTAssertEqual(expected.updatedCount, 1)
        XCTAssertEqual(expected.releasedCount, 1)

        let effectFalse = buildFalse()
        effectFalse.callAll()

        XCTAssertEqual(expected.initializingCount, 1)
        XCTAssertEqual(expected.initializedCount, 1)
        XCTAssertEqual(expected.updatedCount, 1)
        XCTAssertEqual(expected.releasedCount, 1)
    }

    @MainActor
    func testMixed() {
        let expected0 = TestEffect()
        let expected1 = TestEffect()
        let expected2 = TestEffect()
        let expected3 = TestEffect()
        let expected4 = TestEffect()
        let expected5 = TestEffect()
        let expected6 = TestEffect()
        let expected7 = TestEffect()

        @AtomEffectBuilder
        func build() -> some AtomEffect {
            expected0
            expected1

            if true {
                expected2
            }

            if true {
                expected3
            }
            else if false {
                expected4
            }
            else {
                expected5
            }

            if #available(iOS 1, *) {
                expected6
            }
            else {
                expected7
            }
        }

        let effect = build()
        effect.callAll()

        let expectedEffects = [
            expected0,
            expected1,
            expected2,
            expected3,
            expected6,
        ]
        let unexpectedEffects = [
            expected4,
            expected5,
            expected7,
        ]

        for expected in expectedEffects {
            XCTAssertEqual(expected.initializingCount, 1)
            XCTAssertEqual(expected.initializedCount, 1)
            XCTAssertEqual(expected.updatedCount, 1)
            XCTAssertEqual(expected.releasedCount, 1)
        }

        for unexpected in unexpectedEffects {
            XCTAssertEqual(unexpected.initializingCount, 0)
            XCTAssertEqual(unexpected.initializedCount, 0)
            XCTAssertEqual(unexpected.updatedCount, 0)
            XCTAssertEqual(unexpected.releasedCount, 0)
        }
    }
}

private extension AtomEffect {
    func callAll() {
        let context = AtomCurrentContext(store: .dummy)
        initializing(context: context)
        initialized(context: context)
        updated(context: context)
        released(context: context)
    }
}
