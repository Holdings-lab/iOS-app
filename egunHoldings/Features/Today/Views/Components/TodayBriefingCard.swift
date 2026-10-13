import SwiftUI

// MARK: - Briefing (Section 1)

struct TodayBriefingCard: View {
    let briefing: TodayBriefing
    let isAccountLinked: Bool

    var body: some View {
        if isAccountLinked {
            linkedContent
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
        } else {
            // 온보딩 7/8 건너뛰기 확인과 같은 문구를 유지한다 — 한쪽만 바꾸면 안내가 어긋난다.
            Text("계좌 없이 시작할 수 있어요\n일부 기능은 연결 후 사용 가능해요")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
        }
    }

    private var linkedContent: some View {
        let accent = briefing.severity.accentColor

        return HStack(alignment: .center, spacing: 0) {
            if let accent {
                Rectangle().fill(accent).frame(width: 4)
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("고점 대비")
                        .font(.pretendard(10.5, weight: .bold))
                        .tracking(0.2)
                        .foregroundStyle(Color.textQuaternary)

                    Text(drawdownText)
                        .font(.pretendard(24, weight: .bold))
                        .foregroundStyle(numberColor)
                        .monospacedDigit()

                    Text("전일 대비 \(dailyChangeText)")
                        .font(.pretendard(10.5, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.muted, in: Capsule())
                }
                .frame(width: 92, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "고점 대비 \(directionWord) \(abs(Int(briefing.drawdownFromPeakPercent.rounded())))퍼센트, 전일 대비 \(dailyChangeText)"
                )

                Text(briefing.message)
                    .font(.pretendard(14, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 16)
            .padding(.leading, accent == nil ? 16 : 12)
            .padding(.trailing, 16)
        }
    }

    private var numberColor: Color {
        briefing.severity.drawdownColor(for: briefing.drawdownFromPeakPercent)
    }

    private var drawdownText: String {
        let value = briefing.drawdownFromPeakPercent
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(Int(value.rounded()))%"
    }

    private var dailyChangeText: String {
        let value = briefing.todayChangePercent
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    private var directionWord: String {
        if briefing.drawdownFromPeakPercent > 0 { return "상승" }
        if briefing.drawdownFromPeakPercent < 0 { return "하락" }
        return "보합"
    }
}
