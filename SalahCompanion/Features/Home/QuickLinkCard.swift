import SwiftUI

/// A compact tappable card used on Home to navigate to a feature (Habit
/// Consistency, Qibla Direction). Styled as an elevated surface with an icon
/// badge, title, and short subtitle.
struct QuickLinkCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(16)
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.appPrimary.opacity(0.06), radius: 10, y: 4)
    }
}

#Preview {
    HStack(spacing: 12) {
        QuickLinkCard(
            systemImage: "chart.bar.fill",
            title: "Habit Consistency",
            subtitle: "Streak & calendar"
        )
        QuickLinkCard(
            systemImage: "location.north.line.fill",
            title: "Qibla Direction",
            subtitle: "Find the Kaaba"
        )
    }
    .padding()
    .background(Color.appBackground)
}
