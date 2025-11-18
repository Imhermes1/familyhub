import Foundation
import CoreLocation
import Combine

@MainActor
class PulseLocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?

    private var onGeofenceEnter: ((String) -> Void)?
    private var onGeofenceExit: ((String) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission Management

    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    var hasLocationPermission: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    var canUseGeofences: Bool {
        return authorizationStatus == .authorizedAlways
    }

    // MARK: - Location Updates

    func startUpdatingLocation() {
        guard hasLocationPermission else {
            print("Location permission not granted")
            return
        }
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func getCurrentLocation() async throws -> CLLocation {
        guard hasLocationPermission else {
            throw LocationError.permissionDenied
        }

        // Request one-time location
        locationManager.requestLocation()

        // Wait for location update (simplified - in production use proper async handling)
        if let location = lastLocation {
            return location
        }

        throw LocationError.locationUnavailable
    }

    // MARK: - Geofencing

    func createGeofence(
        identifier: String,
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        onEnter: @escaping (String) -> Void,
        onExit: @escaping (String) -> Void
    ) {
        guard canUseGeofences else {
            print("Geofencing requires 'Always' location permission")
            return
        }

        self.onGeofenceEnter = onEnter
        self.onGeofenceExit = onExit

        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)
    }

    func removeGeofence(identifier: String) {
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: region)
        }
    }

    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    func createHomeGeofence(latitude: Double, longitude: Double, radius: Double, onEnter: @escaping () -> Void, onExit: @escaping () -> Void) {
        createGeofence(
            identifier: "home",
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            radius: radius,
            onEnter: { _ in onEnter() },
            onExit: { _ in onExit() }
        )
    }

    func createWorkGeofence(latitude: Double, longitude: Double, radius: Double, onEnter: @escaping () -> Void, onExit: @escaping () -> Void) {
        createGeofence(
            identifier: "work",
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            radius: radius,
            onEnter: { _ in onEnter() },
            onExit: { _ in onExit() }
        )
    }

    // MARK: - Reverse Geocoding

    func getLocationName(for location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        if let placemark = placemarks.first {
            if let name = placemark.name {
                return name
            } else if let locality = placemark.locality {
                return locality
            } else if let administrativeArea = placemark.administrativeArea {
                return administrativeArea
            }
        }

        return "Unknown Location"
    }
}

// MARK: - CLLocationManagerDelegate

extension PulseLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            // Track permission changes
            PostHogManager.shared.track("permission_granted", properties: [
                "permission_type": "location",
                "status": authorizationStatus.description
            ])
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                lastLocation = location
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            print("Entered region: \(region.identifier)")
            onGeofenceEnter?(region.identifier)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            print("Exited region: \(region.identifier)")
            onGeofenceExit?(region.identifier)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Geofence monitoring failed: \(error.localizedDescription)")
    }
}

// MARK: - Errors

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission is required"
        case .locationUnavailable:
            return "Unable to determine location"
        case .geocodingFailed:
            return "Failed to get location name"
        }
    }
}

// MARK: - Extensions

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "not_determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorized_always"
        case .authorizedWhenInUse:
            return "authorized_when_in_use"
        @unknown default:
            return "unknown"
        }
    }
}
