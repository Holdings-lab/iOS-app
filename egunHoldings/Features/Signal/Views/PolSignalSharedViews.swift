import SwiftUI

struct PolSignalFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct PolSignalChip: View {
    let text: String
    let color: Color
    var isProminent = false

    var body: some View {
        Text(text)
            .font(.pretendard(11, weight: .bold))
            .foregroundStyle(isProminent ? Color.white : color)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(isProminent ? color : color.opacity(0.1), in: Capsule())
    }
}

struct PolSignalSectionTitle: View {
    let title: String
    let caption: String?

    init(_ title: String, caption: String? = nil) {
        self.title = title
        self.caption = caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.pretendard(18, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            if let caption {
                Text(caption)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PolSignalTodayBriefingView: View {
    let events: [PolSignalEvent]
    let proposal: PolSignalAdjustmentProposal?
    let onEventTap: (PolSignalEvent) -> Void
    let onProposalTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            topImpactSection
            policyEventSection

            if let proposal {
                pendingProposalCard(proposal)
            }
        }
    }

    private var topImpactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("내 포트폴리오 영향 Top 3")

            VStack(spacing: 10) {
                ForEach(events.prefix(3)) { event in
                    Button {
                        onEventTap(event)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            PolSignalChip(text: event.exposures.first?.ticker ?? event.category, color: event.accentColor, isProminent: true)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.verdict)
                                    .font(.pretendard(14, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(event.reason)
                                    .font(.pretendard(12, weight: .medium))
                                    .foregroundStyle(Color.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.textQuaternary)
                                .padding(.top, 4)
                        }
                        .padding(14)
                        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
        }
    }

    private var policyEventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("오늘 점검할 정책 이벤트")

            if let event = events.first {
                Button {
                    onEventTap(event)
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            PolSignalChip(text: event.dDay, color: event.accentColor, isProminent: true)
                            PolSignalChip(text: event.category, color: event.accentColor)
                            Spacer(minLength: 0)
                            Text(event.institution)
                                .font(.pretendard(11, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.title)
                                .font(.pretendard(17, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(2)

                            Text(event.expectedImpact)
                                .font(.pretendard(13, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 6) {
                            Text("상세 보기")
                                .font(.pretendard(12, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(event.accentColor)
                    }
                    .padding(16)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
    }

    private func pendingProposalCard(_ proposal: PolSignalAdjustmentProposal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("대응 대기 중")

            Button(action: onProposalTap) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 36, height: 36)
                        .background(Color.brand.opacity(0.1), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(proposal.title)
                            .font(.pretendard(14, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)

                        Text(proposal.allocationChanges.joined(separator: " / "))
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.brand)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.textQuaternary)
                }
                .padding(14)
                .background(Color.brand.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.brand.opacity(0.16), lineWidth: 1)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }
}

struct PolSignalAssetSnapshotView: View {
    let summary: PolSignalAssetSummary
    let proposal: PolSignalAdjustmentProposal?
    let onProposalTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let proposal {
                proposalBanner(proposal)
            }

            totalAssetCard
            riskSection
            themeExposureSection
        }
    }

    private func proposalBanner(_ proposal: PolSignalAdjustmentProposal) -> some View {
        Button(action: onProposalTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("조정 제안")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.brand)

                    Text(proposal.title)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    Text("제안 보기")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.brand)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.brand)
            }
            .padding(16)
            .background(Color.brand.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.brand.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var totalAssetCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(summary.totalAssetText)
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .monospacedDigit()

                Text(summary.returnBadgeText)
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(summary.returnColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(summary.returnColor.opacity(0.1), in: Capsule())
            }

            compositionBar
            compositionLegend
        }
        .padding(18)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var compositionBar: some View {
        GeometryReader { proxy in
            HStack(spacing: 3) {
                ForEach(summary.composition) { item in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(item.color)
                        .frame(width: max(6, proxy.size.width * item.percent / totalComposition))
                }
            }
        }
        .frame(height: 10)
    }

    private var compositionLegend: some View {
        PolSignalFlowLayout(spacing: 7) {
            ForEach(summary.composition) { item in
                HStack(spacing: 5) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 7, height: 7)

                    Text("\(item.title) \(Int(item.percent))%")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("포트폴리오 위험 신호")

            VStack(spacing: 10) {
                ForEach(summary.riskAlerts) { alert in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: alert.severity == .red ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(alert.color)
                            .frame(width: 28, height: 28)
                            .background(alert.color.opacity(0.1), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.title)
                                .font(.pretendard(14, weight: .bold))
                                .foregroundStyle(Color.textPrimary)

                            Text(alert.detail)
                                .font(.pretendard(12, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(alert.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(alert.color.opacity(0.18), lineWidth: 1)
                    }
                }
            }
        }
    }

    private var themeExposureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalSectionTitle("주요 테마 노출")

            VStack(spacing: 12) {
                ForEach(summary.themeExposures) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(item.title)
                                .font(.pretendard(13, weight: .bold))
                                .foregroundStyle(Color.textPrimary)

                            Spacer()

                            Text("\(Int(item.percent))%")
                                .font(.pretendard(13, weight: .bold))
                                .foregroundStyle(item.color)
                                .monospacedDigit()
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.subtle)

                                Capsule()
                                    .fill(item.color)
                                    .frame(width: max(0, proxy.size.width * item.percent / 100))
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(16)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
    }

    private var totalComposition: Double {
        max(summary.composition.reduce(0) { $0 + $1.percent }, 1)
    }
}
