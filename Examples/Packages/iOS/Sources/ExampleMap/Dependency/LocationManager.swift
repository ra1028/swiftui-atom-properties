import CoreLocation

protocol LocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var location: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }

    func stopUpdatingLocation()
}

extension CLLocationManager: LocationManagerProtocol {}

final class MockLocationManager: LocationManagerProtocol {
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy = kCLLocationAccuracyKilometer
    var location: CLLocation? = nil
    var authorizationStatus = CLAuthorizationStatus.notDetermined
    var isUpdatingLocation = true

    func stopUpdatingLocation() {
        isUpdatingLocation = false
    }
}
