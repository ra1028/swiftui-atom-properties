import SwiftUI
import XCTest

@testable import Atoms

@MainActor
final class AtomStoreEnvironmentTests: XCTestCase {
    func testAtomStore() {
        var environmentValues = EnvironmentValues()

        XCTAssertTrue(environmentValues.atomStore is DefaultAtomStore)

        environmentValues.atomStore = RootAtomStore(store: Store())

        XCTAssertTrue(environmentValues.atomStore is RootAtomStore)
    }
}
