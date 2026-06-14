import CoreLocation
import Observation

/// A location resolved to a display name, coordinates, and timezone — ready
/// to be stored on `UserSettings` and passed to `PrayerTimeService`. Always
/// carries the *location's* timezone, which may differ from the device's.
struct ResolvedLocation: Sendable, Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
    let timeZone: TimeZone
}

/// Resolves the device's current location (automatic mode) or a searched
/// place name (manual mode) to a `ResolvedLocation`, using CoreLocation's
/// async APIs.
@MainActor
@Observable
final class LocationService {
    enum LocationError: Error {
        /// The user has denied location permission.
        case authorizationDenied
        /// No location could be determined.
        case locationUnavailable
        /// The resolved place has no associated timezone.
        case timeZoneUnavailable
        /// A search/reverse-geocode query matched no places.
        case placeNotFound
    }

    private let geocoder = CLGeocoder()

    /// Current "when in use" authorization status. Re-read on each access
    /// since CLLocationManager doesn't expose this as `@Observable` state.
    var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager().authorizationStatus
    }

    /// Requests "when in use" location permission. No-op if already
    /// determined.
    func requestAuthorization() {
        CLLocationManager().requestWhenInUseAuthorization()
    }

    /// Resolves the device's current coordinates, place name, and timezone
    /// for "automatic" location mode. Stops after the first usable update.
    func currentLocation() async throws -> ResolvedLocation {
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied {
                throw LocationError.authorizationDenied
            }
            guard let location = update.location,
                  location.horizontalAccuracy >= 0 else { continue }
            return try await resolvedLocation(for: location)
        }
        throw LocationError.locationUnavailable
    }

    /// Geocodes a free-text place name (e.g. "Cairo, Egypt") for "manual"
    /// location mode.
    func location(forSearchText text: String) async throws -> ResolvedLocation {
        let placemarks = try await geocoder.geocodeAddressString(text)
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw LocationError.placeNotFound
        }
        return try resolvedLocation(from: placemark, location: location)
    }

    private func resolvedLocation(for location: CLLocation) async throws -> ResolvedLocation {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LocationError.placeNotFound
        }
        return try resolvedLocation(from: placemark, location: location)
    }

    private func resolvedLocation(from placemark: CLPlacemark, location: CLLocation) throws -> ResolvedLocation {
        guard let timeZone = placemark.timeZone else {
            throw LocationError.timeZoneUnavailable
        }
        let name = [placemark.locality, placemark.country]
            .compactMap { $0 }
            .joined(separator: ", ")
        return ResolvedLocation(
            name: name.isEmpty ? "Unknown Location" : name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timeZone: timeZone
        )
    }
}
