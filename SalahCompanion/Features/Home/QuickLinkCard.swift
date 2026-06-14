import SwiftUI

/// A compact tappable card used on Home to navigate to a feature (Habit
/// Consistency, Qibla Direction). Styled as a soft surface with an icon,
/// title, and short subtitle.
struct QuickLinkCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.appPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(16)
        .background(Color.appPrimaryLight.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 12) {
        QuickLinkCard(
            systemImage: "chart.bar.fill",
            title: "Habit Consistency",
            subtitle: "Your prayer streak"
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
