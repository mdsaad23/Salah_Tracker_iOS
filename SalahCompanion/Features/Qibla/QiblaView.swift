import CoreLocation
import SwiftUI

/// Qibla compass: a radar-style dial that keeps true north oriented to the
/// world while a glowing marker points toward the Kaaba. Pass the user's
/// coordinates; heading comes live from `QiblaService`.
struct QiblaView: View {
    let coordinate: CLLocationCoordinate2D?

    @State private var service = QiblaService()

    private var qiblaBearing: Double? {
        coordinate.map(QiblaService.bearing(from:))
    }

    private var distanceKm: Double? {
        coordinate.map(QiblaService.distanceKm(from:))
    }

    var body: some View {
        VStack(spacing: 28) {
            if let qiblaBearing {
                compass(qiblaBearing: qiblaBearing)
                readout(qiblaBearing: qiblaBearing)
                if service.headingAccuracy < 0 || service.headingAccuracy > 20 {
                    calibrationNote
                }
            } else {
                ContentUnavailableView(
                    "Location needed",
                    systemImage: "location.slash",
                    description: Text("Set a location on the Home screen to find the Qibla.")
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
        .navigationTitle("Qibla Direction")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { service.start() }
        .onDisappear { service.stop() }
    }

    private func compass(qiblaBearing: Double) -> some View {
        let heading = service.trueHeading ?? 0
        return ZStack {
            // Ambient glow behind the dial.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.16), .clear],
                        center: .center, startRadius: 20, endRadius: 170
                    )
                )
                .frame(width: 320, height: 320)

            // Dial face.
            Circle()
                .fill(Color.appCardSurface)
                .frame(width: 280, height: 280)
                .shadow(color: Color.appPrimary.opacity(0.08), radius: 20, y: 8)

            // Radar rings.
            ForEach([1.0, 0.7, 0.4], id: \.self) { scale in
                Circle()
                    .strokeBorder(Color.appPrimary.opacity(0.08), lineWidth: 1)
                    .frame(width: 280 * scale, height: 280 * scale)
            }

            // Cardinal letters, rotated so N tracks true north.
            cardinalLetters
                .rotationEffect(.degrees(-heading))

            // Line + marker pointing to the Kaaba relative to where the phone faces.
            qiblaIndicator(bearing: qiblaBearing - heading)

            // Device marker, fixed at the dial's center.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.appTextSecondary.opacity(0.35))
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(45))
        }
        .frame(width: 320, height: 320)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.2), value: heading)
    }

    private var cardinalLetters: some View {
        ZStack {
            cardinal("N", angle: 0)
            cardinal("E", angle: 90)
            cardinal("S", angle: 180)
            cardinal("W", angle: 270)
        }
    }

    private func cardinal(_ letter: String, angle: Double) -> some View {
        Text(letter)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(letter == "N" ? Color.appMissed : Color.appTextSecondary)
            .offset(y: -126)
            .rotationEffect(.degrees(angle))
    }

    /// A gradient line from the dial's center to a glowing marker, rotated to
    /// `bearing` degrees from straight up so it always points to the Kaaba.
    private func qiblaIndicator(bearing: Double) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 16, height: 16)
                .shadow(color: Color.appPrimary.opacity(0.5), radius: 6)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimaryLight.opacity(0.2)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 124)
            Spacer()
        }
        .frame(height: 280)
        .rotationEffect(.degrees(bearing))
    }

    private func readout(qiblaBearing: Double) -> some View {
        VStack(spacing: 12) {
            Text(alignmentHint(qiblaBearing: qiblaBearing))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.appPrimary)

            VStack(spacing: 4) {
                if let distanceKm {
                    Text(distanceLabel(distanceKm))
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
                Text("\(Int(qiblaBearing.rounded()))° from North")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.appTextSecondary.opacity(0.8))
            }

            if let heading = service.trueHeading {
                facingPill(heading: heading)
            } else {
                Text("Detecting heading…")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private func facingPill(heading: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "location.north.fill")
                .font(.caption)
            Text(facingLabel(heading: heading))
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.appPrimary)
        .textCase(.uppercase)
        .tracking(0.8)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appCardSurface)
        .clipShape(Capsule())
        .shadow(color: Color.appPrimary.opacity(0.06), radius: 8, y: 2)
    }

    private var calibrationNote: some View {
        Label("Move your phone in a figure-8 to calibrate the compass.", systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(Color.appUpcoming)
            .multilineTextAlignment(.center)
    }

    /// Difference between where the phone points and the Qibla, as a hint.
    private func alignmentHint(qiblaBearing: Double) -> String {
        let heading = service.trueHeading ?? 0
        let delta = (qiblaBearing - heading + 540).truncatingRemainder(dividingBy: 360) - 180
        if abs(delta) < 5 {
            return String(localized: "Facing the Qibla")
        }
        return delta > 0
            ? String(localized: "Turn right")
            : String(localized: "Turn left")
    }

    /// Great-circle distance to the Kaaba, formatted with localized units.
    private func distanceLabel(_ km: Double) -> String {
        let formatted = Measurement(value: km, unit: UnitLength.kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .road))
        return String(localized: "\(formatted) away")
    }

    /// Nearest 8-point cardinal abbreviation for a true heading in degrees.
    private func cardinalDirection(for heading: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((heading / 45).rounded()) % directions.count
        return directions[(index + directions.count) % directions.count]
    }

    private func facingLabel(heading: Double) -> String {
        String(localized: "Facing \(cardinalDirection(for: heading))")
    }
}

#Preview {
    NavigationStack {
        QiblaView(coordinate: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708))
    }
}
