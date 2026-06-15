---
name: salah-companion
description: Design tokens and domain reference (color palette, typography, layout rules, prayer time calculation methods, Qibla bearing formula, Hijri date handling) for the Salah Companion iOS app. Use whenever working on UI/SwiftUI views, prayer time logic, Qibla compass, widgets, notifications, or App Intents in this project.
---

# Salah Companion — Design & Domain Reference

## Design Tokens

### Colors
- Primary (deep emerald): `#1F3D2E` — headers, primary buttons, hero card background
- Primary light (sage/teal accent): `#2E5945` — secondary surfaces, gradients
- Background (pale mint/sage): `#E7F2EC` — base background, light mode
- Card surface (`appCardSurface`): `#FCFEFD` — elevated cards/panels, near-white
  against the mint background. Inset panels *within* a card (e.g. the "next
  prayer" pill, the Qibla dial face) reuse `appBackground` for a two-tone look.
- Accent (muted gold): `#C9A24B` — used **sparingly only**: streak badges. Never
  as a large fill.
- Text primary: near-black/charcoal `#1C1C1A`
- Text secondary / muted: soft grey `#8A8F87`
- Dark mode: invert — near-black background `#12201A`, card surface `#1C2E25`,
  cream text `#F5F1E8`, same gold accent

### Layout Pattern (Nafs-inspired)
- Pill/capsule shapes for small interactive elements: location indicator,
  refresh button (circular), "facing X" badges.
- Icon badges: small circular tinted-fill backgrounds (`appPrimary.opacity(0.1)`)
  behind feature icons on quick-link tiles.
- Soft glow shadows on focal elements (active prayer circle, Qibla marker) using
  the element's own color at low opacity, not generic black shadows.
- Calendar/heatmap cells show the day number inside a progress ring (ring fill
  proportional to prayers completed that day), with today highlighted by a
  soft `appPrimary.opacity(0.12)` fill — not a plain dot grid.

### Typography
- One typeface family throughout (rounded/geometric sans, e.g. system font with
  rounded design, or a single custom font). Avoid mixing serif + sans.
- Countdown numerals: large, tabular/monospaced digits so they don't jitter while
  ticking.
- Arabic prayer names rendered alongside English (Fajr / الفجر) using a typeface
  that pairs visually with the Latin font; ensure RTL-safe layout for Arabic text.

### Layout Rules
- One primary focal element per screen (e.g. the Next Prayer hero card on Home).
- Generous whitespace/padding (≥16pt screen margins, ≥12pt between elements).
- Corner radius 16–24pt on cards; soft, low-opacity shadows only.
- No imagery of humans or animals. Optional faint (≤8% opacity) Islamic geometric
  pattern (8-pointed star / arabesque line work) as background texture — never
  competing with foreground content.
- Motion: ease-in-out, 300–400ms transitions. Countdown should tick smoothly
  (update every second via `TimelineView`, not abrupt jumps).

## Prayer Time Calculation

- Library: **Adhan-swift** (SPM: `https://github.com/batoulapps/Adhan-swift`).
  Computes times entirely offline from coordinates + date + timezone.
- Inputs needed per calculation: latitude, longitude, date, **timezone of the
  selected location** (not the device's timezone — important when the user tracks
  a different region), calculation method, madhab.
- Calculation methods to expose in Settings (with short plain-language blurbs):
  Muslim World League, Egyptian, Karachi, Umm al-Qura (Makkah), Dubai, Moonsighting
  Committee, North America (ISNA), Kuwait, Qatar, Singapore, Tehran, Turkey (Diyanet).
- Madhab affects **Asr** time only: Shafi/standard (earlier) vs. Hanafi (later,
  shadow length = 2x object).
- High-latitude rule (e.g. `.twilightAngle` / `.seventhOfNight` / `.middleOfNight`
  in Adhan-swift) is required for locations roughly beyond ±48° latitude where
  Fajr/Isha may not be well-defined astronomically.
- Always compute "today's" and "tomorrow's" times together — needed for the
  countdown to wrap correctly overnight (e.g. counting down to tomorrow's Fajr
  after Isha has passed).

## Qibla Bearing

- Kaaba coordinates: **21.4225° N, 39.8262° E**.
- Initial great-circle bearing from user location (lat1, lon1) to Kaaba (lat2,
  lon2), in radians:

  ```
  Δlon = lon2 - lon1
  y = sin(Δlon) * cos(lat2)
  x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(Δlon)
  bearing = atan2(y, x)
  ```

  Convert to degrees and normalize to 0–360° (`(degrees + 360) % 360`).
- Compass UI rotates the Kaaba marker to `bearing - deviceHeading` (true heading,
  not magnetic) so the marker points to Qibla regardless of phone orientation.
- Show a calibration prompt if `CLHeading.headingAccuracy` is poor/negative.

## Hijri Date

- Use `Calendar(identifier: .islamicUmmAlQura)` for display.
- Hijri date can be off by ±1 day from local moon-sighting announcements — expose
  a manual ±1 day adjustment in Settings, applied as an offset to the computed
  Hijri date.

## Data Model Conventions

- `UserSettings`: location mode (auto/manual), saved location (lat/lon/timezone/
  name), calculation method, madhab, tracked prayers (subset of Fajr/Sunrise/
  Dhuhr/Asr/Maghrib/Isha), per-prayer notification prefs, time format, Hijri offset.
- `DailyPrayerTimes`: date, location snapshot, computed times for all 6 markers
  (Fajr/Sunrise/Dhuhr/Asr/Maghrib/Isha).
- `PrayerLog`: date, prayer name, status (`prayedOnTime` / `prayedLate` / `missed` /
  `notTracked`), timestamp marked.
- Store all of the above in SwiftData inside the shared **App Group** container so
  the widget extension and App Intents extension can read the same data without
  duplicating the prayer-time calculation.

## Alarms, Siri Shortcuts & App Intents Notes

- Use **AlarmKit** (iOS 26+) to schedule real system alarms directly from the app
  — Lock Screen, Dynamic Island, StandBy, and paired Apple Watch UI, can break
  through Focus/Silent mode. This is why the project's minimum deployment target
  is iOS 26 (see CLAUDE.md). Full patterns in the `alarmkit` skill.
- Flow: `PrayerTimeService` computes the target prayer time → apply the user's
  offset (e.g. −5 min for "before Fajr", +10 min for "after Zuhr") → `AlarmService`
  calls `AlarmManager.schedule(...)` with `AlarmAttributes`/`AlarmPresentation` for
  that one-shot alarm.
- Expose this as an **App Intent** (e.g. "Set an alarm [offset] minutes
  [before/after] [prayer]") so Siri/Shortcuts can trigger it directly — see the
  `app-intents` skill for parameterized intents and Siri phrase donation.
- AlarmKit requires explicit user authorization (similar to notifications) —
  request it with a calm, clear explanation, not on first launch.
- Older approach (pre-AlarmKit): chaining an App Intent's `Date` output into
  Shortcuts' built-in "Adjust Date" + "Create Alarm" actions. Keep this only as a
  fallback if the iOS 26 minimum ever needs to be lowered.
