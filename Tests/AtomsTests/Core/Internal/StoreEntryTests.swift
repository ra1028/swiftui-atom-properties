import XCTest

@testable import Atoms

@MainActor
final class StoreEntryTests: XCTestCase {
    func testWeakStoreEntry() {
        var host: AtomHostBase? = AtomHostBase()
        let entry = WeakStoreEntry(host: host)

        XCTAssertNotNil(entry.host)

        host = nil

        XCTAssertNil(entry.host)
    }

    func testKeepAliveStoreEntry() {
        var host: AtomHostBase? = AtomHostBase()
        let entry = KeepAliveStoreEntry(host: host)

        XCTAssertNotNil(entry.host)

        host = nil

        XCTAssertNotNil(entry.host)
    }
}
