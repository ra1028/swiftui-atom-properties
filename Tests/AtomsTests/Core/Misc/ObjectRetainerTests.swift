import XCTest

@testable import Atoms

@MainActor
final class ObjectRetainerTests: XCTestCase {
    func testRelease() {
        var object: Object? = Object()
        weak var objectRef = object
        let retainer = ObjectRetainer(object!)

        XCTAssertNotNil(objectRef)

        object = nil
        XCTAssertNotNil(objectRef)

        retainer.release()
        XCTAssertNil(objectRef)
    }
}
