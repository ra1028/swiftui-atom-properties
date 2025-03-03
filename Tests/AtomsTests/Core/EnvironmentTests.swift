import SwiftUI
import XCTest

@testable import Atoms

final class EnvironmentTests: XCTestCase {
    @MainActor
    func testStore() {
        let store = AtomStore()
        let atom = TestValueAtom(value: 0)
        var environment = EnvironmentValues()

        store.state.caches = [AtomKey(atom): AtomCache(atom: atom, value: 100)]
        environment.store = .root(store: store)

        XCTAssertEqual(environment.store?.read(atom), 100)
    }
}
