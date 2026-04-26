import SwiftUI

struct HomePortfolioSummaryCard: View {
    let snapshot: PortfolioSnapshot
    let riskTitle: String
    let riskReason: String
    let exposureItems: [PolicyExposureSummaryItem]
    let exposureTitle: (PolicyExposureSummaryItem) -> String
    @State private var showsExposureFootnote = false

    var body: some View {
        HomeGlassCard(
            variant: .secondary,
            padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("내 포트폴리오 현황")
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(Color(hex: "92A4D8"))

                amountSection
                riskSection
                exposureHeader
                exposureSection
            }
        }
    }

    private var amountSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("총 자산")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.72))

                Text(snapshot.amountText)
                    .font(.pretendard(26, weight: .bold))
                    .foregroundStyle(Color.foreground)
                    .tracking(-0.8)
                    .monospacedDigit()
                    .minimumScaleFactor(0.76)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Image(systemName: snapshot.changePercentText.hasPrefix("-") ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))

                Text(snapshot.changePercentText)
                    .font(.pretendard(13, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(changeTint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(changeTint.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(changeTint.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: changeTint.opacity(0.12), radius: 12, y: 4)
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("현재 리스크")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.8))

                RiskPill(title: riskTitle)
            }

            Text(condensedRiskReason)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.9))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exposureHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("주요 노출")
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.8))

                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        showsExposureFootnote.toggle()
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mutedForeground.opacity(0.72))
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            if showsExposureFootnote {
                Text("노출 수치는 중복 포함 가능하며 합계 100%와 다를 수 있어요.")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(Color.mutedForeground.opacity(0.76))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var exposureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(exposureItems) { item in
                HStack(spacing: 12) {
                    Text(exposureTitle(item))
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.84))
                        .frame(width: 74, alignment: .leading)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 5)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [item.color.opacity(0.42), item.color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(22, proxy.size.width * CGFloat(item.exposurePercent) / 100),
                                    height: 5
                                )
                                .shadow(color: item.color.opacity(0.35), radius: 6)
                        }
                    }
                    .frame(height: 5)

                    Text("\(item.exposurePercent)%")
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(item.color)
                        .frame(width: 42, alignment: .trailing)
                        .monospacedDigit()
                }
            }
        }
        .padding(.top, 4)
    }

    private var changeTint: Color {
        snapshot.changePercentText.hasPrefix("-") ? .policyCoral : .emerald
    }

    private var condensedRiskReason: String {
        riskReason
            .replacingOccurrences(of: "정책 충격이 와도 2주 방어 버퍼는 있어요.", with: "2주 방어 버퍼는 확보돼 있어요.")
            .replacingOccurrences(of: "반도체와 금리 경로에 노출이 몰려 있어요.", with: "반도체와 금리 노출이 한쪽에 몰려 있어요.")
            .replacingOccurrences(of: "지금은 리밸런싱보다 체크포인트 관리가 먼저예요.", with: "지금은 매매보다 체크포인트 확인이 먼저예요.")
    }
}

private struct RiskPill: View {
    let title: String

    private var tint: Color {
        switch title {
        case "안정", "양호", "낮음":
            return .emerald
        case "위험":
            return .policyCoral
        default:
            return .policyAmber
        }
    }

    var body: some View {
        Text(title)
            .font(.pretendard(11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.24), lineWidth: 1)
            }
    }
}
