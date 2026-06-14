# Xcode Setup (macOS-only, Phase 1)

The `SalahCompanion/` folder contains source files scaffolded on Windows.
These steps need Xcode on macOS and only have to be done once.

1. **Create the Xcode project**
   - File > New > Project > iOS > App.
   - Product Name: `SalahCompanion`. Interface: SwiftUI. Language: Swift.
   - Set the deployment target to **iOS 26**.
   - Save it at the repo root so the project sits alongside `SalahCompanion/`.

2. **Add the scaffolded sources**
   - Remove the default `ContentView.swift` and the auto-generated
     `*App.swift` (replaced by `SalahCompanionApp.swift`).
   - Remove Xcode's default `Assets.xcassets` (or merge its `AppIcon`/
     `AccentColor` entries into `SalahCompanion/Resources/Assets.xcassets`,
     which already has the design-token color sets from Phase 3).
   - Drag the existing `SalahCompanion/Core`, `Features`, `Widgets`,
     `AppIntents`, `Resources`, `SalahCompanionApp.swift`, and
     `SalahCompanion.entitlements` into the project, ensuring "Copy items if
     needed" is unchecked (keep them in place) and they're added to the
     `SalahCompanion` app target.
   - Confirm `Resources/Assets.xcassets` and `Resources/Localizable.xcstrings`
     have target membership for `SalahCompanion` so `Color("PrimaryEmerald")`
     etc. and the EN/AR strings resolve at runtime.

3. **Add the Adhan-swift dependency**
   - File > Add Package Dependencies > `https://github.com/batoulapps/Adhan-swift`.
   - Add to the `SalahCompanion` app target **and** the `SalahCompanionTests`
     target (needed by `PrayerTimeServiceTests.swift`).
   - `Core/Services/PrayerTimeService.swift` was written without access to the
     package source — once added, verify the API names called out in the
     comment at the top of that file (`CalculationMethod.params`,
     `CalculationParameters.highLatitudeRule`/`HighLatitudeRule` case names,
     `PrayerTimes.init(coordinates:date:calculationParameters:)`) and fix any
     mismatches.

4. **Enable the App Group capability**
   - Target `SalahCompanion` > Signing & Capabilities > + Capability > App
     Groups.
   - Add a group, e.g. `group.<your-team-id>.salahcompanion`.
   - Update the placeholder identifier `group.com.example.salahcompanion` in
     both `SalahCompanionApp.swift` (`appGroupIdentifier`) and
     `SalahCompanion.entitlements` to match.
   - Repeat this capability for the widget extension and App Intents
     extension targets once they exist (Phase 8/9), using the same group ID.

5. **Wire up Info.plist**
   - Merge `SalahCompanion/Resources/Info.plist`'s
     `NSLocationWhenInUseUsageDescription` into the app target's Info tab (or
     point the target's `INFOPLIST_FILE` build setting at this file).

6. **Build and run** on a Simulator to confirm the project compiles and shows
   the Home screen. To exercise the Phase 3 UI in the Simulator: Debug >
   Simulate Location to give the automatic-location flow a coordinate (the
   Home screen requests "when in use" permission on first launch).

7. **Add the test target sources**
   - If the project was created with "Include Tests" checked, Xcode already
     created a `SalahCompanionTests` target/folder. Add
     `SalahCompanionTests/PrayerTimeServiceTests.swift` to that target (or
     move it into the generated folder) and run the tests — they cover DST
     transitions, midnight rollover, and a high-latitude location.
