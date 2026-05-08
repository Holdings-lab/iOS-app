import SwiftUI

struct LowRelevanceSheet: View {
    let item: PolicyNewsItem
    let onOpen: () -> Void

    var body: some View {
        ZStack {
            Color.elevated.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("우선순위 낮음 이유")
                        .font(.pretendard(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(item.newsroomSourceTimeText)
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(item.title)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(Color.divider)
                        .frame(height: 1)

                    Text("현재 포트폴리오와 관련 없는 이유")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.5))

                    Text(item.newsroomWhyIgnoreText)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.textPrimary.opacity(0.6))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .glassCard()

                Button(action: onOpen) {
                    Text("그래도 보기")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textPrimary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            Color.elevated.opacity(0.8),
                            in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())

                NewsInvestmentDisclaimer()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    LowRelevanceSheet(item: HomeNewsMockData.items[5], onOpen: {})
}
