import SwiftUI

/// Typed accessors for the design tokens defined in
/// `Resources/Assets.xcassets` (see `salah-companion` skill for the palette).
extension Color {
    /// Deep emerald — headers, primary buttons, hero card background.
    static let appPrimary = Color("PrimaryEmerald")

    /// Sage/teal accent — secondary surfaces and gradients.
    static let appPrimaryLight = Color("PrimaryLight")

    /// Muted gold — used sparingly: next-prayer highlight, streak badges,
    /// Qibla marker. Never as a large fill.
    static let appAccent = Color("AccentGold")

    /// Base screen background. Pale mint/sage in light mode, near-black in dark.
    static let appBackground = Color("BackgroundPrimary")

    /// Elevated card/surface fill. Near-white in light mode, lifted dark green
    /// in dark mode — sits above `appBackground` to create the two-tone
    /// layering used for cards and their inset panels.
    static let appCardSurface = Color("CardSurface")

    /// Primary body text. Charcoal in light mode, cream in dark.
    static let appTextPrimary = Color("TextPrimary")

    /// Secondary/muted text, e.g. captions and Arabic prayer names.
    static let appTextSecondary = Color("TextSecondary")

    /// Fixed light text/icon color for content drawn on the always-emerald
    /// `appPrimary` surfaces, regardless of light/dark mode.
    static let appTextOnPrimary = Color("TextOnPrimary")

    /// Muted clay rose — marks a missed prayer. A warm red that sits with the
    /// emerald/cream/gold palette rather than a clinical alert red.
    static let appMissed = Color("MissedRose")

    /// Warm amber — marks the upcoming/next prayer (ring + center dot).
    static let appUpcoming = Color("UpcomingAmber")
}
