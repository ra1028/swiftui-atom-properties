import SwiftUI
import XCTest

@testable import Atoms

@MainActor
final class EnvironmentTests: XCTestCase {
    func testStore() {
        let store = AtomStore()
        let storeContext = StoreContext(store)
        let atom = TestValueAtom(value: 0)
        var environment = EnvironmentValues()

        store.state.caches = [AtomKey(atom): AtomCache(atom: atom, value: 100)]
        environment.store = storeContext

        XCTAssertEqual(environment.store.read(atom), 100)
    }
}
