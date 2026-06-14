import SwiftData
import SwiftUI
import UIKit

/// Home screen: today's date (Gregorian + Hijri), the next-prayer hero card
/// with a live countdown, and today's full prayer list with the upcoming
/// prayer highlighted.
struct HomeView: View {
    @Query private var settingsList: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()

    var body: some View {
        Group {
            if let settings = settingsList.first {
                content(settings: settings)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            }
        }
        .task {
            if settingsList.isEmpty {
                modelContext.insert(UserSettings())
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
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let next = viewModel.nextPrayer(after: context.date, trackedPrayers: settings.trackedPrayers)
                    VStack(alignment: .leading, spacing: 20) {
                        if let next {
                            NextPrayerCard(prayer: next.prayer, time: next.time)
                        }
                        prayerList(today: today, next: next)
                    }
                }
            }
        }
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

    private func prayerList(today: DailyPrayerTimes, next: (prayer: Prayer, time: Date)?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today's Prayers")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .padding(.bottom, 4)

            ForEach(Prayer.allCases) { prayer in
                PrayerRow(
                    prayer: prayer,
                    time: today.time(for: prayer),
                    isNext: next?.prayer == prayer
                )
            }
        }
        .padding(16)
        .background(Color.appPrimaryLight.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
