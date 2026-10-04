import SwiftUI

// MARK: - Empty ("quiet") state shared by Holdings / Goal cards

struct TodayQuietState: View {
    var iconName: String? = nil
    let message: Text
    var ctaTitle: String? = nil
    var onCTA: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.textQuaternary)
            }

            message
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            if let ctaTitle, let onCTA {
                Button(action: onCTA) {
                    Text(ctaTitle)
                        .font(.pretendard(13.5, weight: .bold))
                        .foregroundStyle(Color.textOnAccent)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 18)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(PSPressStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }
}
