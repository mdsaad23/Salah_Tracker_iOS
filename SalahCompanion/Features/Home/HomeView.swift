import CoreLocation
import SwiftData
import SwiftUI
import UIKit

/// Home screen: today's date (Gregorian + Hijri), a tracker card for logging
/// today's prayers with a live countdown to the next one, and quick links to
/// the Habit Consistency and Qibla screens.
struct HomeView: View {
    /// A destination reachable from the Home screen. `qibla` carries plain
    /// coordinates so the route stays `Hashable` (CLLocationCoordinate2D isn't).
    enum Route: Hashable {
        case consistency
        case qibla(latitude: Double, longitude: Double)
    }

    @Query private var settingsList: [UserSettings]
    @Query private var allLogs: [PrayerLog]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let settings = settingsList.first {
                    content(settings: settings)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appBackground)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .consistency:
                    ConsistencyView()
                case let .qibla(latitude, longitude):
                    QiblaView(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }
        }
        .task {
            if settingsList.isEmpty {
                if UITestConfiguration.isSeeding {
                    UITestConfiguration.seed(into: modelContext)
                } else {
                    modelContext.insert(UserSettings())
                }
            }
        }
    }

    private func content(settings: UserSettings) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(settings: settings)
                mainContent(settings: settings)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .task {
            await viewModel.refresh(using: settings)
            applyUITestScreen(settings: settings)
        }
    }

    /// In UI-test/screenshot runs, opens the screen named by the launch argument.
    private func applyUITestScreen(settings: UserSettings) {
        guard path.isEmpty, let screen = UITestConfiguration.initialScreen else { return }
        switch screen {
        case "consistency":
            path = [.consistency]
        case "qibla":
            path = [.qibla(
                latitude: viewModel.today?.latitude ?? settings.latitude,
                longitude: viewModel.today?.longitude ?? settings.longitude
            )]
        default:
            break
        }
    }

    @ViewBuilder
    private func mainContent(settings: UserSettings) -> some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

        case .needsLocationPermission:
            permissionPrompt

        case .failed:
            errorPrompt(settings: settings)

        case .loaded:
            if let today = viewModel.today {
                let tracked = trackedPrayers(settings: settings)
                VStack(spacing: 20) {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        PrayerTrackerCard(
                            trackedPrayers: tracked,
                            today: today,
                            statuses: statuses(on: today.date),
                            next: viewModel.nextPrayer(after: context.date, trackedPrayers: tracked),
                            now: context.date,
                            onLog: { prayer, status in
                                setLog(prayer, to: status, dayStart: today.date)
                            }
                        )
                    }
                    quickLinks(today: today)
                }
            }
        }
    }

    private func quickLinks(today: DailyPrayerTimes) -> some View {
        HStack(spacing: 12) {
            NavigationLink(value: Route.consistency) {
                QuickLinkCard(
                    systemImage: "chart.bar.fill",
                    title: "Habit Consistency",
                    subtitle: "Streak & calendar"
                )
            }

            NavigationLink(value: Route.qibla(latitude: today.latitude, longitude: today.longitude)) {
                QuickLinkCard(
                    systemImage: "location.north.line.fill",
                    title: "Qibla Direction",
                    subtitle: "Find the Kaaba"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func header(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(date: .long, time: .omitted))
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            Text(HijriDate.formatted(for: .now, offsetDays: settings.hijriDateOffsetDays))
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)

            Button {
                Task { await viewModel.refresh(using: settings) }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                    Text(locationLabel(settings: settings))
                }
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.top, 4)
        }
    }

    private var permissionPrompt: some View {
        VStack(spacing: 12) {
            Text("Location access is needed to calculate accurate prayer times.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextPrimary)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func errorPrompt(settings: UserSettings) -> some View {
        VStack(spacing: 12) {
            Text("Unable to load prayer times.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextPrimary)

            Button("Try Again") {
                Task { await viewModel.refresh(using: settings) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Logging

    /// Tracked obligatory prayers in canonical order.
    private func trackedPrayers(settings: UserSettings) -> [Prayer] {
        Prayer.allCases.filter { $0.isObligatory && settings.trackedPrayers.contains($0) }
    }

    /// Today's logged statuses keyed by prayer.
    private func statuses(on dayStart: Date) -> [Prayer: PrayerStatus] {
        var result: [Prayer: PrayerStatus] = [:]
        for log in allLogs where Calendar.current.isDate(log.date, inSameDayAs: dayStart) {
            result[log.prayer] = log.status
        }
        return result
    }

    /// Creates, updates, or (when `status` is `nil`) clears the log for a
    /// prayer on the given day, persisting to the shared SwiftData store.
    private func setLog(_ prayer: Prayer, to status: PrayerStatus?, dayStart: Date) {
        let existing = allLogs.first {
            $0.prayer == prayer && Calendar.current.isDate($0.date, inSameDayAs: dayStart)
        }

        if let status {
            if let existing {
                existing.status = status
                existing.markedAt = .now
            } else {
                modelContext.insert(
                    PrayerLog(date: dayStart, prayer: prayer, status: status, markedAt: .now)
                )
            }
        } else if let existing {
            modelContext.delete(existing)
        }

        try? modelContext.save()
    }

    private func locationLabel(settings: UserSettings) -> String {
        if let resolved = viewModel.resolvedLocationName, !resolved.isEmpty {
            return resolved
        }
        if !settings.locationName.isEmpty {
            return settings.locationName
        }
        return String(localized: "Current Location")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserSettings.self, DailyPrayerTimes.self, PrayerLog.self], inMemory: true)
}
