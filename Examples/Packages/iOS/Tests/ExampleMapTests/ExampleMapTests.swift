import Atoms
import CoreLocation
import Testing

@testable import ExampleMap

struct ExampleMapTests {
    @MainActor
    @Test
    func testLocationObserverAtom() {
        let atom = LocationObserverAtom()
        let context = AtomTestContext()
        let manager = MockLocationManager()

        context.override(atom) { _ in
            LocationObserver(manager: manager)
        }

        context.watch(atom)

        #expect(manager.delegate != nil)
        #expect(manager.isUpdatingLocation)

        context.unwatch(atom)

        #expect(!manager.isUpdatingLocation)
    }

    @MainActor
    @Test
    func testCoordinateAtom() {
        let atom = CoordinateAtom()
        let context = AtomTestContext()
        let manager = MockLocationManager()

        context.override(LocationObserverAtom()) { _ in
            LocationObserver(manager: manager)
        }

        manager.location = CLLocation(latitude: 1, longitude: 2)

        #expect(context.watch(atom)?.latitude == 1)
        #expect(context.watch(atom)?.longitude == 2)
    }

    @MainActor
    @Test
    func testAuthorizationStatusAtom() async {
        let atom = AuthorizationStatusAtom()
        let manager = MockLocationManager()
        let context = AtomTestContext()
        let observer = LocationObserver(manager: manager)

        context.override(LocationObserverAtom()) { _ in
            observer
        }

        manager.authorizationStatus = .authorizedWhenInUse

        #expect(context.watch(atom) == .authorizedWhenInUse)

        manager.authorizationStatus = .authorizedAlways

        Task {
            observer.objectWillChange.send()
        }

        await context.waitForUpdate()

        #expect(context.watch(atom) == .authorizedAlways)

        observer.objectWillChange.send()
        let didUpdate = await context.waitForUpdate(timeout: 0.1)

        // Should not update if authorizationStatus is not changed.
        #expect(!didUpdate)
    }
}
