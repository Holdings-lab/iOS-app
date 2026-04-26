import SwiftUI

enum PolicyDetailTab: String, CaseIterable, Identifiable {
    case summary = "요약"
    case evidence = "근거"
    case checkpoints = "체크포인트"

    var id: String { rawValue }
}

struct PolicyImpactDetailSheet: View {
    let policy: HomeImpactPolicy
    let initialTab: PolicyDetailTab

    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: PolicyDetailTab
    @State private var isUpdateExpanded = false

    init(policy: HomeImpactPolicy, initialTab: PolicyDetailTab = .summary) {
        self.policy = policy
        self.initialTab = initialTab
        _activeTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 12)

            header
            tabBar

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    switch activeTab {
                    case .summary:
                        summaryContent
                    case .evidence:
                        evidenceContent
                    case .checkpoints:
                        checkpointsContent
                    }

                    Text("본 분석은 AI 기반 자동 생성 자료이며, 투자 권유가 아닙니다.")
                        .font(.pretendard(10, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.56))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 26)
                .id(activeTab)
            }
        }
        .background(
            Color(hex: "0C1133").opacity(0.95)
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(policy.title)
                    .font(.pretendard(17, weight: .bold))
                    .foregroundStyle(Color.foreground)
                    .lineLimit(2)

                Text("내 자산 영향권 \(policy.meta.exposurePercent)%")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.84))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.foreground)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.05), in: Circle())
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var tabBar: some View {
        HStack(spacing: 22) {
            ForEach(PolicyDetailTab.allCases) { tab in
                Button {
                    withAnimation(.smooth(duration: 0.22)) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.rawValue)
                            .font(.pretendard(14, weight: .semibold))
                            .foregroundStyle(activeTab == tab ? Color.foreground : Color.mutedForeground.opacity(0.82))

                        Rectangle()
                            .fill(activeTab == tab ? Color.electricBlue : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeGlassCard(variant: .secondary, padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("지금 판단")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.82))

                    ActionKeywordPill(action: policy.judgment.action)

                    Text(policy.quickActionSupportText)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.86))
                        .lineLimit(1)
                }
            }

            HomeGlassCard(variant: .secondary, padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
                VStack(spacing: 0) {
                    DetailSummaryRow(title: "내 자산 영향권", value: policy.judgment.relevanceSummary)
                    DetailSummaryRow(title: "핵심 이유", value: policy.judgment.keyReason)
                    DetailSummaryRow(title: "다시 볼 시점", value: policy.judgment.validUntilSummary, titleColor: Color.policyAmber.opacity(0.88))
                    DetailSummaryRow(title: "판단 약화 조건", value: policy.judgment.failureSummary, titleColor: Color.policyCoral.opacity(0.88), showsDivider: false, topSpacing: 4)
                }
            }
        }
    }

    private var evidenceContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeGlassCard(variant: .secondary, padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("정책 영향 경로")
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(Color.foreground)

                    ForEach(policy.transmissionPath) { step in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top, spacing: 12) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(step.color.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        Image(systemName: step.symbol)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(step.color)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.pretendard(12, weight: .semibold))
                                        .foregroundStyle(Color.foreground)

                                    Text(plainEvidenceText(step.subtitle))
                                        .font(.pretendard(12, weight: .medium))
                                        .foregroundStyle(Color.mutedForeground.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()
                            }

                            if step.id != policy.transmissionPath.last?.id {
                                Rectangle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 1, height: 14)
                                    .padding(.leading, 18)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }

            HomeGlassCard(variant: .secondary, padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("핵심 근거")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.foreground)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(policy.meta.supportingEvidence.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.pretendard(11, weight: .bold))
                                    .foregroundStyle(Color.emerald.opacity(0.74))
                                    .frame(width: 18, height: 18)
                                    .background(Color.emerald.opacity(0.1), in: Circle())

                                Text(plainEvidenceText(item))
                                    .font(.pretendard(12, weight: .medium))
                                    .foregroundStyle(Color.foreground.opacity(0.82))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)

                    DetailEvidenceGroup(
                        title: "반대 근거",
                        titleColor: Color.policyAmber.opacity(0.8),
                        lines: [plainEvidenceText(policy.meta.counterEvidence)]
                    )

                    DetailEvidenceGroup(
                        title: "무효화 조건",
                        titleColor: Color.policyCoral.opacity(0.8),
                        lines: splitListText(plainEvidenceText(policy.meta.invalidationCondition))
                    )
                }
            }
        }
    }

    private var checkpointsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            checkpointGroup(
                title: "정책 확인 숫자",
                items: policy.checkpoints.filter { $0.category == .policy || $0.category == nil }
            )

            checkpointGroup(
                title: "시장 반응 신호",
                items: policy.checkpoints.filter { $0.category == .market }
            )

            HomeGlassCard(variant: .secondary, padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("다시 볼 알림")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.foreground)

                    ForEach(policy.alerts, id: \.self) { alert in
                        HStack(spacing: 8) {
                            Image(systemName: "bell")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.mutedForeground.opacity(0.45))

                            Text(alert)
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(Color.foreground.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HomeGlassCard(variant: .secondary, padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)) {
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            isUpdateExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text("현재 반영 상태")
                                .font(.pretendard(13, weight: .semibold))
                                .foregroundStyle(Color.mutedForeground.opacity(0.82))

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mutedForeground.opacity(0.78))
                                .rotationEffect(.degrees(isUpdateExpanded ? 180 : 0))
                        }
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    if isUpdateExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("마지막 업데이트 \(policy.meta.updateSummary.updatedAtText)")
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.foreground.opacity(0.78))

                            Text("반영 출처: \(policy.meta.updateSummary.sourceText)")
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground.opacity(0.84))
                                .fixedSize(horizontal: false, vertical: true)

                            Text("검토: \(policy.meta.updateSummary.compactReviewText)")
                                .font(.pretendard(11, weight: .semibold))
                                .foregroundStyle(Color.emerald.opacity(0.82))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checkpointGroup(title: String, items: [WeeklyPolicyCheckpoint]) -> some View {
        Group {
            if items.isEmpty == false {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.foreground)

                    ForEach(items) { checkpoint in
                        HomeGlassCard(
                            variant: .secondary,
                            padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
                        ) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(checkpoint.threshold)
                                    .font(.pretendard(16, weight: .bold))
                                    .foregroundStyle(Color.foreground)
                                    .tracking(-0.3)

                                Text(checkpoint.title)
                                    .font(.pretendard(12, weight: .medium))
                                    .foregroundStyle(Color.mutedForeground.opacity(0.82))

                                Text(checkpoint.whyItMatters)
                                    .font(.pretendard(11, weight: .medium))
                                    .foregroundStyle(Color.mutedForeground.opacity(0.78))
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func plainEvidenceText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "CAPEX 가이던스", with: "설비투자 계획")
            .replacingOccurrences(of: "세액공제율", with: "세금 감면 비율")
    }

    private func splitListText(_ text: String) -> [String] {
        text
            .components(separatedBy: "거나, ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}

private struct DetailSummaryRow: View {
    let title: String
    let value: String
    var titleColor: Color = Color.mutedForeground.opacity(0.72)
    var showsDivider: Bool = true
    var topSpacing: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(titleColor)

            Text(value)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.foreground.opacity(0.88))
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, topSpacing)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
            }
        }
    }
}

private struct DetailEvidenceGroup: View {
    let title: String
    let titleColor: Color
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(11, weight: .semibold))
                .foregroundStyle(titleColor)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.foreground.opacity(0.74))
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
