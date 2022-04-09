import CoreLocation

protocol LocationManagerProtocol {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var location: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
}

extension CLLocationManager: LocationManagerProtocol {}

final class MockLocationManager: LocationManagerProtocol {
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy = kCLLocationAccuracyKilometer
    var location: CLLocation? = nil
    var authorizationStatus = CLAuthorizationStatus.notDetermined
}
