import CoreLocation
import SwiftUI

/// Qibla compass: a dial that keeps true north oriented to the world while a
/// gold marker points toward the Kaaba. Pass the user's coordinates; heading
/// comes live from `QiblaService`.
struct QiblaView: View {
    let coordinate: CLLocationCoordinate2D?

    @State private var service = QiblaService()

    private var qiblaBearing: Double? {
        coordinate.map(QiblaService.bearing(from:))
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
            Circle()
                .fill(Color.appPrimaryLight.opacity(0.08))
            Circle()
                .strokeBorder(Color.appTextSecondary.opacity(0.25), lineWidth: 2)

            // Cardinal letters, rotated so N tracks true north.
            cardinalLetters
                .rotationEffect(.degrees(-heading))

            // Qibla marker, pointing to the Kaaba relative to where the phone faces.
            qiblaMarker
                .rotationEffect(.degrees(qiblaBearing - heading))

            Circle()
                .fill(Color.appPrimary)
                .frame(width: 12, height: 12)
        }
        .frame(width: 280, height: 280)
        .padding(.top, 24)
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
            .font(.headline.weight(.semibold))
            .foregroundStyle(letter == "N" ? Color.appMissed : Color.appTextSecondary)
            .offset(y: -120)
            .rotationEffect(.degrees(angle))
    }

    private var qiblaMarker: some View {
        VStack(spacing: 4) {
            Image(systemName: "location.north.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.appAccent)
            Image(systemName: "cube.fill")
                .font(.title3)
                .foregroundStyle(Color.appAccent)
            Spacer()
        }
        .frame(height: 280)
    }

    private func readout(qiblaBearing: Double) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(qiblaBearing.rounded()))° from North")
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
            if service.trueHeading != nil {
                Text(alignmentHint(qiblaBearing: qiblaBearing))
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                Text("Detecting heading…")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
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
}

#Preview {
    NavigationStack {
        QiblaView(coordinate: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708))
    }
}
