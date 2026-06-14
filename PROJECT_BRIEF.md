# Project Brief — Salah Companion iOS App

This is the standing brief for building this app with Claude Code. Combine with
[CLAUDE.md](CLAUDE.md) (conventions, environment, structure) and the
`salah-companion` project skill (`.claude/skills/salah-companion/SKILL.md`, design
tokens + domain formulas).

## App Vision

A native iOS app (SwiftUI, iOS 26+ — see CLAUDE.md for why) that helps Muslims stay
consistent with the 5 daily prayers. Inspired by apps like "Nafs" but with
**original branding, name, and visual design** — do not copy their assets.

Core promise: at a glance, the user should know **what prayer is next, how much time
is left, and how they're doing with consistency** — without clutter, ads, or visual
noise. The tone is calm, spacious, and reverent. (Possible name directions to pick
from later: Sakeenah, Waqt, Rabita, Mizan — pick one before App Store setup.)

## MVP Feature Set

1. **Accurate prayer times** for any location/timezone, computed offline via a real
   astronomical calculation library.
2. **Prayer selection** — user chooses which of the 5 (or 6, including optional
   sunrise/Duha) prayers to actively track/be notified about.
3. **Home screen**: current time, today's date (Gregorian + Hijri), "Next Prayer"
   hero card with live countdown, list of all today's prayer times with the
   current/next one highlighted.
4. **Consistency tracking**: mark each prayer prayed (on time / late) or missed;
   streaks, weekly/monthly completion stats, simple calendar/heatmap view.
5. **Qibla compass**: live compass pointing to the Kaaba using device location +
   heading.
6. **Location**: auto-detect via GPS, or manually search/select a city — including
   locations the user doesn't currently live in.
7. **Widgets**: Home Screen (small/medium/large) and Lock Screen widgets showing
   today's prayer times and/or the next-prayer countdown.
8. **Siri Shortcuts / App Intents / AlarmKit**: let users say "set an alarm 5
   minutes before Fajr" or "10 minutes after Zuhr adhaan" and get a real system
   alarm (Lock Screen + Dynamic Island), scheduled via AlarmKit.
9. **Local notifications** for each tracked prayer at its calculated time.

## Development Phases — work through in order

Use TaskCreate to track these as a checklist for the session(s). Don't start a
phase until its dependencies are solid — widgets and Shortcuts depend on the shared
data models and prayer-time engine from Phase 1–2.

### Phase 1 — Project Setup
- New Xcode project, SwiftUI App lifecycle, iOS 26 deployment target.
- Folder structure per CLAUDE.md (`Core/`, `Features/`, `Widgets/`, `AppIntents/`).
- Add `Adhan-swift` SPM dependency.
- App Group capability + location permission strings (`Info.plist`).
- SwiftData model container shared via the App Group.

### Phase 2 — Prayer Time Engine & Location
- Location manager: permission, coordinates + timezone, reverse geocoding.
- Manual location picker (search city; store lat/lon/timezone/name).
- `PrayerTimeService` wrapping Adhan for today's + tomorrow's times, given
  calculation method + madhab (see `salah-companion` skill for formulas/methods).
- Unit tests: DST transitions, midnight rollover, high-latitude edge cases.

### Phase 3 — Home Screen
- "Next Prayer" hero card with live countdown.
- Today's prayer list, current/next highlighted with the gold accent.
- Gregorian + Hijri date header.
- Location display with quick switch.

### Phase 4 — Consistency Tracking
- `PrayerLog` SwiftData model + CRUD.
- Tap-to-mark prayer as prayed (on-time/late) once its time has passed.
- Stats screen: current/longest streak, weekly/monthly completion rate, calendar
  heatmap.
- Respect tracked-prayer selection from settings.

### Phase 5 — Qibla Compass
- Circular compass UI, smooth rotation, Kaaba marker.
- Great-circle bearing calculation (formula in `salah-companion` skill),
  calibration messaging.

### Phase 6 — Settings
- Location mode (auto/manual) + manual picker.
- Calculation method + madhab pickers, with plain-language descriptions.
- Tracked-prayers toggle list.
- Per-prayer notification toggles + offsets.
- Time format, appearance (light/dark/system), Hijri date adjustment (±1 day).

### Phase 7 — Notifications
- Schedule/reschedule local notifications for tracked prayers.
- Background task (`BGTaskScheduler`) to refresh schedule daily and on location
  change.

### Phase 8 — Widgets
- Home Screen widgets: small (next prayer + countdown), medium (next prayer +
  today's row), large (full day + Hijri date).
- Lock Screen widgets: circular countdown, rectangular next-prayer text.
- Shared data via App Group; timeline refresh at each prayer boundary.

### Phase 9 — Siri Shortcuts, App Intents & AlarmKit
- `AlarmService` (Core/Services) wrapping `AlarmManager` to schedule/cancel
  AlarmKit alarms relative to a prayer time (e.g. Fajr − 5 min, Zuhr + 10 min).
  See the `alarmkit` skill for `AlarmAttributes`/`AlarmPresentation` patterns.
- App Intents for "set an alarm [offset] [before/after] [prayer]", "time for
  [prayer]", and "time until next prayer" — these are what Siri/Shortcuts invoke.
  See the `app-intents` skill for parameterized intent + Siri phrase patterns.
- Request AlarmKit authorization with a clear, calm explanation screen.
- Surface a small in-app gallery of common alarm shortcuts (e.g. "5 min before
  Fajr", "10 min after Zuhr") that just call the App Intent directly — no need to
  chain through the Shortcuts app's "Adjust Date"/"Create Alarm" actions now that
  AlarmKit exists.
- Confirm AlarmKit's iOS 26 minimum is acceptable (it's why Phase 1 set the
  deployment target to iOS 26); if broader OS support is later required, fall back
  to the Shortcuts "Adjust Date" + "Create Alarm" chaining approach for older OSes.

### Phase 10 — Polish & QA
- Full dark mode pass.
- Accessibility: Dynamic Type, VoiceOver labels for countdown and compass.
- Localization scaffolding for English + Arabic (RTL layout check).
- App icon + launch screen matching the calm aesthetic (use `canvas-design` /
  `algorithmic-art` skills for assets).
- Manual QA across timezones, DST boundaries, location changes — requires macOS +
  Xcode/Simulator (see CLAUDE.md environment note).

## Working Notes
- Keep the UI minimal at every step — if a screen feels crowded, prefer removing or
  deferring an element over shrinking it.
- Flag iOS API limitations (especially Shortcuts/alarms, background refresh) as
  soon as discovered, with a proposed fallback, rather than silently changing scope.
- Run `code-review` / `simplify` after finishing each phase before moving to the
  next.
- Anything requiring `xcodebuild`, Simulator, or device testing needs a macOS
  environment — if unavailable, finish the code and clearly note what still needs
  verification.
