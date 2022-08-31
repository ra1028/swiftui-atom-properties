import SwiftUI
import XCTest

@testable import Atoms

@MainActor
final class EnvironmentTests: XCTestCase {
    func testStore() {
        let store = Store()
        let atom = TestValueAtom(value: 0)
        var environment = EnvironmentValues()

        store.state.atomCaches = [AtomKey(atom): AtomCache(atom: atom, value: 100)]
        environment.store = StoreContext(store)

        XCTAssertEqual(environment.store.read(atom), 100)
    }
}
