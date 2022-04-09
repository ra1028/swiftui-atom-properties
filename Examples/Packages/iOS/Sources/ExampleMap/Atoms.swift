import Atoms
import CoreLocation

struct LocationManagerAtom: ValueAtom, Hashable {
    func value(context: Context) -> LocationManagerProtocol {
        let manager = CLLocationManager()
        let delegate = LocationManagerDelegate()

        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
        context.addTermination(manager.stopUpdatingLocation)
        context.keepUntilTermination(delegate)
        delegate.onChange = {
            context.reset(AuthorizationStatusAtom())
        }

        return manager
    }
}

struct CoordinateAtom: ValueAtom, Hashable {
    func value(context: Context) -> CLLocationCoordinate2D? {
        let manager = context.watch(LocationManagerAtom())
        return manager.location?.coordinate
    }
}

struct AuthorizationStatusAtom: ValueAtom, Hashable {
    func value(context: Context) -> CLAuthorizationStatus {
        let manager = context.watch(LocationManagerAtom())
        return manager.authorizationStatus
    }
}

private final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var onChange: (() -> Void)?

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onChange?()

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
