# Xcode Setup (macOS-only, Phase 1)

The `SalahCompanion/` folder contains source files scaffolded on Windows.
The `.xcodeproj` is **generated, not committed** (see `.gitignore`) from
[`project.yml`](project.yml) via [XcodeGen](https://github.com/yonaskolb/XcodeGen).
`codemagic.yaml` runs this automatically on its macOS CI runner. To regenerate
locally on macOS:

```sh
brew install xcodegen
xcodegen generate
```

Remaining steps that need a macOS/Simulator session:

1. **Verify the Adhan-swift API** — `Core/Services/PrayerTimeService.swift`
   was written without access to the package source. Once
   `xcodegen generate` resolves the `Adhan` SPM dependency (declared in
   `project.yml`), verify the API names called out in the comment at the top
   of that file (`CalculationMethod.params`,
   `CalculationParameters.highLatitudeRule`/`HighLatitudeRule` case names,
   `PrayerTimes.init(coordinates:date:calculationParameters:)`) and fix any
   mismatches.

2. **Run the tests** — `SalahCompanionTests/PrayerTimeServiceTests.swift`
   covers DST transitions, midnight rollover, and a high-latitude location.

3. **Build and run on a Simulator** to confirm the Home screen looks right.
   Debug > Simulate Location gives the automatic-location flow a coordinate
   (the Home screen requests "when in use" permission on first launch). Also
   check Arabic (RTL) and dark mode.

4. **Real App Group identifier** — `group.com.example.salahcompanion` is a
   placeholder used in `SalahCompanionApp.swift` (`appGroupIdentifier`),
   `SalahCompanion.entitlements`, and `project.yml`
   (`PRODUCT_BUNDLE_IDENTIFIER`). It works as-is on the Simulator (App Groups
   aren't provisioning-checked there). Before a real device build, replace it
   everywhere with your team's identifier, e.g.
   `group.<your-team-id>.salahcompanion`, and add the App Groups capability
   under Signing & Capabilities so Xcode registers it with your Apple
   Developer team.

5. **Widget / App Intents extensions** (Phase 8/9) — once those folders
   exist, add corresponding targets to `project.yml` with the same App Group
   entitlement.
