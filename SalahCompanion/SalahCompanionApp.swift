import SwiftUI
import SwiftData

@main
struct SalahCompanionApp: App {
    /// Identifier of the App Group shared by the main app, widget extension,
    /// and App Intents extension. Must match the "App Groups" capability
    /// configured for each target in Xcode and the entitlements files.
    /// Replace the placeholder below with your team's bundle ID prefix.
    static let appGroupIdentifier = "group.com.example.salahcompanion"

    let modelContainer: ModelContainer = {
        let schema = Schema([
            UserSettings.self,
            DailyPrayerTimes.self,
            PrayerLog.self,
        ])

        guard let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            fatalError(
                "App Group '\(appGroupIdentifier)' is not configured. " +
                "Add the App Groups capability (matching this identifier) to the " +
                "app, widget, and App Intents targets in Xcode."
            )
        }

        let storeURL = appGroupURL.appendingPathComponent("SalahCompanion.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .fontDesign(.rounded)
        }
        .modelContainer(modelContainer)
    }
}
