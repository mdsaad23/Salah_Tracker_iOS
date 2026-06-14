# CLAUDE.md

## Project
**Salah Companion** (working title) — calm, minimal SwiftUI iOS app for prayer
time tracking, consistency tracking, Qibla direction, widgets, and Siri/AlarmKit
integration. Inspired by Nafs but original branding/design.

- Roadmap & MVP spec: [PROJECT_BRIEF.md](PROJECT_BRIEF.md)
- Design tokens + domain formulas: `.claude/skills/salah-companion/SKILL.md`
- Status: Phase 1–3 source written (`SalahCompanion/` — Core/Models, app entry
  with App Group `ModelContainer`, `LocationService`, `PrayerTimeService` +
  `SalahCompanionTests/PrayerTimeServiceTests.swift`, design-token color
  assets + `Color+Palette.swift`, EN/AR `Localizable.xcstrings`, and the Home
  screen — date/Hijri header, `NextPrayerCard` live countdown, `PrayerRow`
  list). The `.xcodeproj` is generated (not committed, see `.gitignore`) from
  `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen);
  `codemagic.yaml` runs `xcodegen generate` then builds/tests on a macOS CI
  runner. See [XCODE_SETUP.md](XCODE_SETUP.md) for the Adhan-swift API points
  to verify once the package resolves, plus remaining one-time setup (real
  App Group, Simulator check). Next: get a green Codemagic build (fix any
  Adhan API mismatches, run tests), check Home screen in Simulator, then
  Phase 4.

## Working Principles
(Adapted from Karpathy's CLAUDE.md guidelines; use judgment on trivial tasks.)
1. Think before coding — state assumptions, surface ambiguity, ask if unclear.
2. Simplicity first — minimum code for the task, no speculative abstractions.
3. Surgical changes — touch only what's needed, match existing style, don't
   refactor unrelated code (mention pre-existing dead code, don't delete it).
4. Goal-driven — define a verification check (e.g. failing test → passing), loop
   until it passes.

## Environment
Developed on **Windows** — Xcode/Simulator/`xcodebuild` need **macOS** and aren't
available here. Write/edit Swift, SwiftUI, project config, and assets; flag
anything needing macOS verification (`run`/`verify` skills are macOS-only).

## Tech Stack
SwiftUI, iOS 26+ (for AlarmKit) · Adhan-swift (SPM, offline prayer times) ·
SwiftData in shared App Group · WidgetKit · App Intents · AlarmKit (native
Fajr/etc. alarms) · CoreLocation + CoreMotion (Qibla)

## Project Structure (target, Phase 1)
```
SalahCompanion/
  Core/Models/    # UserSettings, DailyPrayerTimes, PrayerLog (SwiftData)
  Core/Services/  # PrayerTimeService, LocationService, QiblaService, NotificationService, AlarmService
  Features/       # Home, Tracking, Qibla, Settings, Shortcuts
  Widgets/        # WidgetKit extension
  AppIntents/
  Resources/
```

## Design System (full tokens in salah-companion skill)
Emerald `#1F3D2E` + cream `#FAF8F3` + sparing gold accent `#C9A24B`; one rounded
sans-serif, tabular countdown digits; no human/animal imagery, faint geometric
patterns only; one focal element/screen, 16-24pt corners, slow (300-400ms)
transitions.

## Conventions
- Swift API Design Guidelines naming; one SwiftData model per file in Core/Models
- Calculation logic in Core/Services, views stay declarative
- Localize EN+AR from day one, RTL-safe
- No force-unwraps in shared/service code
- Prayer times always use the *selected location's* timezone, not `.current`

## Skills
- **`salah-companion`** (project skill) — design tokens + domain reference,
  auto-loads for UI/prayer-time/Qibla/widget/Shortcuts work
- **`linkedin-salah-journey`** (project skill) — after finishing a phase in
  PROJECT_BRIEF.md (or any milestone the user flags), offer to draft a short,
  personal LinkedIn post using this skill — see its Milestone Router for the
  angle per phase
- **Swift/iOS** (from [swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills),
  notice in `.claude/skills/SWIFT_SKILLS_NOTICE.md`): swift-language,
  swift-api-design-guidelines, swift-architecture, swift-concurrency,
  swift-testing, swift-codable, swiftdata, swift-security, swiftlint,
  swiftui-patterns, swiftui-layout-components, swiftui-navigation,
  swiftui-animation, swiftui-performance, swiftui-liquid-glass, widgetkit,
  app-intents, alarmkit, core-motion, push-notifications, background-processing,
  permissionkit, mapkit, ios-localization, ios-accessibility, ios-simulator,
  debugging-instruments. Pull more from the same repo (SKILL.md + references only)
  as needed.
- **General**: canvas-design / algorithmic-art (assets), code-review / simplify
  (after each phase), run / verify (macOS only)
