import CoreLocation
import Foundation
import Observation

/// Computes the Qibla bearing and streams the device's true heading so the
/// compass marker can point to the Kaaba regardless of phone orientation.
@MainActor
@Observable
final class QiblaService: NSObject, CLLocationManagerDelegate {
    /// Kaaba coordinates (see `salah-companion` skill).
    static let kaaba = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    /// Device true heading in degrees (0 = north), or `nil` until first update.
    private(set) var trueHeading: Double?
    /// Heading accuracy in degrees; negative means the reading is invalid and a
    /// calibration prompt should be shown.
    private(set) var headingAccuracy: Double = -1

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Initial great-circle bearing (degrees, 0–360) from `origin` to the Kaaba.
    static func bearing(from origin: CLLocationCoordinate2D) -> Double {
        let lat1 = origin.latitude * .pi / 180
        let lat2 = kaaba.latitude * .pi / 180
        let deltaLon = (kaaba.longitude - origin.longitude) * .pi / 180

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Great-circle distance (km) from `origin` to the Kaaba, via the
    /// haversine formula.
    static func distanceKm(from origin: CLLocationCoordinate2D) -> Double {
        let earthRadiusKm = 6371.0
        let lat1 = origin.latitude * .pi / 180
        let lat2 = kaaba.latitude * .pi / 180
        let deltaLat = lat2 - lat1
        let deltaLon = (kaaba.longitude - origin.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let accuracy = newHeading.headingAccuracy
        Task { @MainActor in
            self.trueHeading = heading
            self.headingAccuracy = accuracy
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
}
