import SwiftUI

/// Generalized version of NewsroomEmptyCard (Features/Newsroom/Views/Components/NewsroomStateCards.swift):
/// icon circle + bold title + semibold subtitle, with an optional CTA button.
struct TodayEmptyStateCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    var ctaTitle: String? = nil
    var onCTA: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.muted)
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(Color.brand)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let ctaTitle, let onCTA {
                Button(action: onCTA) {
                    Text(ctaTitle)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textOnAccent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.brand, in: Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .padding(.horizontal, 20)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}
