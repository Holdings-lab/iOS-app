import SwiftUI

enum HomeGlassCardVariant {
    case primary
    case secondary
    case warm
}

struct HomeGlassCard<Content: View>: View {
    let variant: HomeGlassCardVariant
    let padding: EdgeInsets
    let content: Content

    init(
        variant: HomeGlassCardVariant = .primary,
        padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                cardBackground
                    .clipShape(shape)
            }
            .clipShape(shape)
            .contentShape(shape)
            .overlay {
                shape
                    .stroke(borderColor, lineWidth: 1)
            }
            .glassEffect(.regular.tint(glassTint), in: shape)
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(backgroundGradient)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial.opacity(materialOpacity))

            Circle()
                .fill(accentColor.opacity(accentOpacity))
                .frame(width: 220, height: 220)
                .blur(radius: 84)
                .offset(x: -70, y: -90)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 170, height: 170)
                .blur(radius: 70)
                .offset(x: 120, y: 110)
        }
    }

    private var backgroundGradient: LinearGradient {
        switch variant {
        case .primary:
            return LinearGradient(
                colors: [
                    Color(hex: "101634").opacity(0.96),
                    Color(hex: "151E46").opacity(0.95),
                    Color(hex: "0E1532").opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [
                    Color(hex: "0C122D").opacity(0.95),
                    Color(hex: "11193D").opacity(0.94),
                    Color(hex: "0C1430").opacity(0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warm:
            return LinearGradient(
                colors: [
                    Color(hex: "3D2F14").opacity(0.82),
                    Color(hex: "6D5521").opacity(0.76),
                    Color(hex: "2B2211").opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var accentColor: Color {
        switch variant {
        case .primary:
            return .electricBlue
        case .secondary:
            return .policyPurple
        case .warm:
            return .policyAmber
        }
    }

    private var accentOpacity: Double {
        switch variant {
        case .primary:
            return 0.18
        case .secondary:
            return 0.12
        case .warm:
            return 0.18
        }
    }

    private var materialOpacity: Double {
        switch variant {
        case .primary:
            return 0.18
        case .secondary:
            return 0.14
        case .warm:
            return 0.08
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return Color.white.opacity(0.11)
        case .secondary:
            return Color.white.opacity(0.09)
        case .warm:
            return Color.white.opacity(0.14)
        }
    }

    private var glassTint: Color {
        switch variant {
        case .primary, .secondary:
            return Color.white.opacity(0.03)
        case .warm:
            return Color.policyAmber.opacity(0.04)
        }
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}

struct ActionKeywordPill: View {
    let action: PolicyJudgmentAction

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: action.symbol)
                .font(.system(size: 11, weight: .semibold))

            Text(action.rawValue)
                .font(.pretendard(11, weight: .semibold))
        }
        .foregroundStyle(action.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(action.color.opacity(0.12), in: Capsule())
        .overlay {
            Capsule()
                .stroke(action.color.opacity(0.26), lineWidth: 1)
        }
        .glassEffect(.regular.tint(action.color.opacity(0.08)), in: Capsule())
    }
}

struct HomeBriefingCard: View {
    let policy: HomeImpactPolicy
    let actionText: String
    let changeText: String
    let signalCountText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HomeGlassCard(
                variant: .primary,
                padding: EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18)
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("오늘 가장 중요한 변화")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.electricBlue.opacity(0.84))
                        .tracking(0.4)

                    HStack(spacing: 0) {
                        BriefingStatCell(
                            value: "\(policy.meta.exposurePercent)%",
                            label: "내 자산 노출",
                            color: .electricBlue
                        )
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 1, height: 28)
                        BriefingStatCell(
                            value: changeText,
                            label: "포트폴리오",
                            color: changeText.hasPrefix("-") ? .policyCoral : .emerald
                        )
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 1, height: 28)
                        BriefingStatCell(
                            value: signalCountText,
                            label: "시그널",
                            color: .policyPurple
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text(policy.title)
                        .font(.pretendard(21, weight: .bold))
                        .foregroundStyle(Color.foreground)
                        .tracking(-0.3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text("권장 행동")
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.mutedForeground.opacity(0.78))

                        Text(actionText)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(policy.judgment.action.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(policy.judgment.action.color.opacity(0.1), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(policy.judgment.action.color.opacity(0.22), lineWidth: 1)
                            }
                    }
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .shadow(color: Color.electricBlue.opacity(0.12), radius: 18, y: 10)
    }
}

private struct BriefingStatCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.pretendard(10, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.76))
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickInterpretationSheet: View {
    let policy: HomeImpactPolicy
    let checkValue: String
    let checkHint: String
    let onOpenDetail: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                coreDecisionCard
                guideRow
                evidenceButton
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .background(PFGradientBackground())
        .navigationTitle("빠른 해석")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("신호 · \(policy.dDayText)")
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.82))

            Text(policy.title)
                .font(.pretendard(22, weight: .bold))
                .foregroundStyle(Color.foreground)
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var coreDecisionCard: some View {
        HomeGlassCard(variant: .primary, padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("지금 판단")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.82))

                    ActionKeywordPill(action: policy.judgment.action)

                    Text(policy.quickActionSupportText)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.84))
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("내 자산 영향권")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.82))

                    Text(policy.judgment.relevanceSummary)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.foreground.opacity(0.94))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 0) {
                    QuickInterpretationRow(
                        title: "핵심 이유",
                        value: policy.judgment.keyReason
                    )

                    QuickInterpretationRow(
                        title: "확인할 숫자",
                        value: checkValue,
                        titleColor: Color.policyAmber.opacity(0.88),
                        emphasized: checkValue.count <= 12,
                        supporting: checkHint
                    )

                    QuickInterpretationRow(
                        title: "다시 볼 시점",
                        value: policy.judgment.validUntilSummary
                    )

                    QuickInterpretationRow(
                        title: "판단 약화 조건",
                        value: policy.judgment.failureSummary,
                        titleColor: Color.policyCoral.opacity(0.88),
                        showsDivider: false
                    )
                }
            }
        }
    }

    private var guideRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.electricBlue.opacity(0.62))
                .padding(.top, 2)

            Text(policy.quickTipText)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.88))
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }

    private var evidenceButton: some View {
        Button {
            onOpenDetail()
        } label: {
            HStack(spacing: 10) {
                Text("근거 전체 보기")
                    .font(.pretendard(15, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(Color.electricBlue)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(Color.electricBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.electricBlue.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct QuickInterpretationRow: View {
    let title: String
    let value: String
    var titleColor: Color = Color.white.opacity(0.48)
    var emphasized: Bool = false
    var supporting: String? = nil
    var showsDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(titleColor)

            Text(value)
                .font(.pretendard(emphasized ? 18 : 14, weight: emphasized ? .bold : .medium))
                .foregroundStyle(Color.foreground.opacity(0.9))
                .tracking(emphasized ? -0.4 : 0)
                .fixedSize(horizontal: false, vertical: true)

            if let supporting {
                Text(supporting)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.86))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)
            }
        }
    }
}

extension HomeImpactPolicy {
    var homeExposureSummaryText: String {
        let prefix: String

        if title.contains("금리") {
            prefix = "금리 변화 노출"
        } else if title.contains("반도체") {
            prefix = "반도체 정책 노출"
        } else if title.contains("전력망") || title.contains("친환경") {
            prefix = "친환경 정책 노출"
        } else {
            prefix = "내 자산 노출"
        }

        return "\(prefix) \(meta.exposurePercent)%"
    }

    var quickActionSupportText: String {
        switch judgment.action {
        case .hedge:
            return "지금은 공격보다 방어를 먼저 점검할 구간이에요."
        case .wait:
            return "바로 움직이기보다 확인 후 판단해도 늦지 않아요."
        case .increase:
            return "확인 숫자가 맞으면 비중 확대를 검토할 수 있어요."
        case .reduce:
            return "노출이 커지기 전에 비중 축소를 검토할 수 있어요."
        }
    }

    var quickTipText: String {
        if title.contains("금리") {
            return "금리보다 코멘트 톤부터 확인하세요."
        } else if title.contains("반도체") {
            return "총액보다 집행 속도부터 보면 충분해요."
        } else if title.contains("전력망") || title.contains("친환경") {
            return "발표보다 예산 집행 여부를 먼저 보세요."
        }

        return "핵심 숫자 하나만 먼저 확인해도 충분해요."
    }
}

extension PolicyUpdateSummary {
    var compactReviewText: String {
        if reviewText.contains("검토") {
            return "검토 완료"
        }

        if reviewText.contains("반영") || reviewText.contains("업데이트") {
            return "반영 완료"
        }

        return reviewText
    }
}
