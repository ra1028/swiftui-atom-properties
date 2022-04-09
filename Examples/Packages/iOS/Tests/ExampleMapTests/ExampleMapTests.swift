import Atoms
import CoreLocation
import XCTest

@testable import ExampleMap

@MainActor
final class ExampleMapTests: XCTestCase {
    func testCoordinateAtom() {
        let atom = CoordinateAtom()
        let context = AtomTestContext()
        let locationManager = MockLocationManager()

        context.override(LocationManagerAtom()) { _ in locationManager }

        locationManager.location = CLLocation(latitude: 1, longitude: 2)

        XCTAssertEqual(context.watch(atom)?.latitude, 1)
        XCTAssertEqual(context.watch(atom)?.longitude, 2)
    }

    func testAuthorizationStatusAtom() {
        let atom = AuthorizationStatusAtom()
        let locationManager = MockLocationManager()
        let context = AtomTestContext()

        context.override(LocationManagerAtom()) { _ in locationManager }

        locationManager.authorizationStatus = .authorizedWhenInUse

        XCTAssertEqual(context.watch(atom), .authorizedWhenInUse)
    }
}
