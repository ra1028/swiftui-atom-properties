import SwiftUI
import XCTest

@testable import Atoms

@MainActor
final class AtomStoreEnvironmentTests: XCTestCase {
    func testAtomStore() {
        var environmentValues = EnvironmentValues()

        XCTAssertTrue(environmentValues.atomStoreInteractor is DefaultAtomStoreInteractor)

        environmentValues.atomStoreInteractor = RootAtomStoreInteractor(store: NewAtomStore())

        XCTAssertTrue(environmentValues.atomStoreInteractor is RootAtomStoreInteractor)
    }
}
