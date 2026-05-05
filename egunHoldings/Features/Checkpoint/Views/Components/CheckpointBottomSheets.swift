import SwiftUI

struct CheckpointDetailSheet: View {
    let checkpoint: CheckpointItem
    let policy: CheckpointPolicyEvent?
    let decisions: [CheckpointDecisionItem]
    let onToggleAlert: () -> Void

    @State private var alertOn: Bool

    init(
        checkpoint: CheckpointItem,
        policy: CheckpointPolicyEvent?,
        decisions: [CheckpointDecisionItem],
        onToggleAlert: @escaping () -> Void
    ) {
        self.checkpoint = checkpoint
        self.policy = policy
        self.decisions = decisions
        self.onToggleAlert = onToggleAlert
        self._alertOn = State(initialValue: checkpoint.alertOn)
    }

    var body: some View {
        sheetContainer {
            VStack(alignment: .leading, spacing: 14) {
                header

                recommendationCard

                if let policy {
                    whyImportantCard(policy: policy)
                }

                if !decisions.isEmpty {
                    relatedDecisionsCard
                }

                if !checkpoint.relatedAssets.isEmpty {
                    relatedAssetsCard
                }

                infoCard

                disclaimer

                alertButton
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(checkpoint.text)
                .font(PSFont.title(16))
                .foregroundStyle(PSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(checkpoint.linkedPolicyTitle)
                .font(PSFont.semibold(12))
                .foregroundStyle(PSColor.electricBlue.opacity(0.60))
        }
    }

    private var recommendationCard: some View {
        PSGlassCard(variant: .primary, padding: 16) {
            VStack(alignment: .leading, spacing: 13) {
                cardLabel("이렇게 되면 어떻게 할까")

                HStack(alignment: .top, spacing: 12) {
                    recommendationColumn(
                        title: "조건이 맞으면",
                        text: checkpoint.conditionMet,
                        color: PSColor.emerald.opacity(0.65)
                    )

                    recommendationColumn(
                        title: "조건이 안 맞으면",
                        text: checkpoint.conditionNotMet,
                        color: PSColor.yellow.opacity(0.65)
                    )
                }
            }
        }
    }

    private func whyImportantCard(policy: CheckpointPolicyEvent) -> some View {
        PSGlassCard(variant: .secondary, padding: 15) {
            VStack(alignment: .leading, spacing: 10) {
                cardLabel("왜 중요한가")

                ForEach(policy.evidence, id: \.self) { item in
                    evidenceRow(
                        icon: "checkmark.circle",
                        color: PSColor.emerald.opacity(0.65),
                        text: item
                    )
                }

                evidenceRow(
                    icon: "exclamationmark.circle",
                    color: PSColor.yellow.opacity(0.65),
                    text: policy.counterEvidence
                )
            }
        }
    }

    private var relatedDecisionsCard: some View {
        PSGlassCard(variant: .secondary, padding: 15) {
            VStack(alignment: .leading, spacing: 12) {
                cardLabel("이번 정책에 대한 추천")

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(decisions) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 7) {
                                JudgmentTypeBadge(type: item.type)

                                Text(item.title)
                                    .font(PSFont.semibold(12))
                                    .foregroundStyle(PSColor.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Text(item.reason)
                                .font(PSFont.caption(11))
                                .foregroundStyle(Color.white.opacity(0.60))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var relatedAssetsCard: some View {
        PSGlassCard(variant: .secondary, padding: 15) {
            VStack(alignment: .leading, spacing: 10) {
                cardLabel("내 자산 영향")

                CheckpointTagFlow {
                    ForEach(checkpoint.relatedAssets, id: \.self) { asset in
                        assetTag(asset, color: policyColor(for: checkpoint.linkedPolicyId))
                    }
                }
            }
        }
    }

    private var infoCard: some View {
        PSGlassCard(variant: .secondary, padding: 15) {
            HStack(spacing: 10) {
                importanceBadge(checkpoint.importance)

                Text("기준: \(checkpoint.baseline)")
                    .font(PSFont.caption(11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PSColor.electricBlue.opacity(0.65))

            Text("이 정보는 투자 권유가 아니며, 정책 확인을 돕기 위한 참고 자료입니다.")
                .font(PSFont.caption(11))
                .foregroundStyle(Color.white.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var alertButton: some View {
        Button {
            alertOn.toggle()
            onToggleAlert()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: alertOn ? "bell.fill" : "bell.slash")
                    .font(.system(size: 13, weight: .semibold))

                Text(alertOn ? "알림 켜짐" : "알림 받기")
                    .font(PSFont.semibold(13))
            }
            .foregroundStyle(alertOn ? PSColor.electricBlue : Color.white.opacity(0.70))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                (alertOn ? PSColor.electricBlue : Color.white).opacity(alertOn ? 0.10 : 0.04),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        (alertOn ? PSColor.electricBlue : Color.white).opacity(0.12),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(PSPressStyle())
    }

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(PSFont.caption(11))
            .foregroundStyle(Color.white.opacity(0.40))
    }

    private func recommendationColumn(title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(PSFont.semibold(11))
                .foregroundStyle(color)

            Text(text)
                .font(PSFont.body(12))
                .foregroundStyle(Color.white.opacity(0.70))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func evidenceRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .padding(.top, 2)

            Text(text)
                .font(PSFont.caption(11))
                .foregroundStyle(Color.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@ViewBuilder
private func sheetContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
        Color.deepNavy.ignoresSafeArea()

        ScrollView(.vertical, showsIndicators: false) {
            content()
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 30)
        }
    }
}
