import Atoms
import CoreLocation

final class LocationObserver: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager: LocationManagerProtocol

    deinit {
        manager.stopUpdatingLocation()
    }

    init(manager: LocationManagerProtocol) {
        self.manager = manager
        super.init()
        manager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        objectWillChange.send()

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .restricted, .denied:
            break

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

struct LocationObserverAtom: ObservableObjectAtom, Hashable {
    func makeCoordinator() -> LocationManagerProtocol {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }

    func object(context: Context) -> LocationObserver {
        LocationObserver(manager: context.coordinator)
    }
}

struct CoordinateAtom: ValueAtom, Hashable {
    func value(context: Context) -> CLLocationCoordinate2D? {
        let observer = context.watch(LocationObserverAtom())
        return observer.manager.location?.coordinate
    }
}

struct AuthorizationStatusAtom: ValueAtom, Hashable {
    func value(context: Context) -> CLAuthorizationStatus {
        context.watch(LocationObserverAtom().select(\.manager.authorizationStatus))
    }
}
