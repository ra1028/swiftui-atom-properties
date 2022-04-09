import SwiftUI
import XCTest

@testable import Atoms

@MainActor
final class AtomStoreEnvironmentTests: XCTestCase {
    func testAtomStore() {
        var environmentValues = EnvironmentValues()

        XCTAssertTrue(environmentValues.atomStore is DefaultStore)

        environmentValues.atomStore = Store(container: StoreContainer())

        XCTAssertTrue(environmentValues.atomStore is Store)
    }
}
