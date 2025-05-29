import XCTest

@testable import Atoms

final class ScopeKeyTests: XCTestCase {
    @MainActor
    func testDescription() {
        let token = ScopeKey.Token()
        let objectAddress = String(UInt(bitPattern: ObjectIdentifier(token)), radix: 16)

        XCTAssertEqual(token.key.description, "0x\(objectAddress)")
    }
}
