import SwiftUI

// MARK: - ThemeSignalSection

/// Today 탭 "내 포트폴리오 Top 3" 섹션.
/// 섹션 헤더 + ThemeSignalCard 목록을 조합하며,
/// 카드별 독립 확장 상태를 관리한다.
struct ThemeSignalSection: View {
    let signals: [PortfolioThemeSignal]
    /// 카드 내 "왜 그런지 알아보기" 탭 시 호출. 테마를 전달해 Signal 상세 화면으로 이동.
    let onFullAnalysis: (PortfolioThemeSignal.Theme) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            VStack(spacing: 10) {
                ForEach(signals) { signal in
                    ThemeSignalCardWrapper(
                        signal: signal,
                        onFullAnalysis: {
                            onFullAnalysis(signal.theme)
                        }
                    )
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .center) {
            Text("내 포트폴리오 Top 3")
                .font(.pretendard(17, weight: .bold, relativeTo: .headline))
                .foregroundStyle(PSColor.textPrimary)

            Spacer(minLength: 12)

            Text("이번 주 기준")
                .font(.pretendard(11, weight: .medium, relativeTo: .caption))
                .foregroundStyle(PSColor.textFaint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PSColor.surfaceAlt, in: Capsule(style: .continuous))
        }
    }
}

/// 각 카드가 자체 확장 상태를 갖도록 감싸는 private wrapper.
private struct ThemeSignalCardWrapper: View {
    let signal: PortfolioThemeSignal
    let onFullAnalysis: () -> Void

    @State private var isExpanded = false

    var body: some View {
        ThemeSignalCard(
            signal: signal,
            isExpanded: isExpanded,
            onTap: {
                withAnimation(.spring(response: 0.40, dampingFraction: 0.86)) {
                    isExpanded.toggle()
                }
            },
            onFullAnalysis: onFullAnalysis
        )
    }
}

// MARK: - ThemeSignalCard

/// 테마 단위 신호 카드. 세 가지 상태를 처리:
///  - 신호 있음 + 접힘
///  - 신호 있음 + 펼침 (ThemeExpansionContent)
///  - 신호 없음 (ThemeEmptyStateBlock 항상 노출)
struct ThemeSignalCard: View {
    let signal: PortfolioThemeSignal
    let isExpanded: Bool
    let onTap: () -> Void
    let onFullAnalysis: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            if signal.verdictKind == nil {
                // 신호 없음 — 항상 표시, 탭 불가
                ThemeEmptyStateBlock(signal: signal)
            } else if isExpanded,
                      let verdict = signal.verdictKind,
                      let prescription = signal.prescription {
                Divider()
                    .background(PSColor.rule)

                ThemeExpansionContent(
                    verdict: verdict,
                    prescription: prescription,
                    narrativeState: .idle,
                    onRetry: {},
                    onFullAnalysis: onFullAnalysis
                )
                .transition(
                    reduceMotion
                        ? .opacity
                        : .opacity.combined(with: .move(edge: .top))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous)
                .stroke(PSColor.border, lineWidth: 1)
        }
        .shadow(color: PSColor.cardShadow, radius: 4, x: 0, y: 1)
        .contentShape(RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous))
        .onTapGesture {
            guard signal.verdictKind != nil else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
        .accessibilityHint(a11yHint)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            themeIconView

            VStack(alignment: .leading, spacing: 3) {
                Text(signal.theme.displayName)
                    .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                    .foregroundStyle(PSColor.textPrimary)
                    .lineLimit(1)

                Text("보유비중 \(signal.myExposurePercent)%")
                    .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(PSColor.textSecondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 8)

            if let verdict = signal.verdictKind {
                SentimentPill(kind: verdict)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isExpanded ? verdict.sentimentForeground : PSColor.textFaint)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.40, dampingFraction: 0.86),
                        value: isExpanded
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 64)
    }

    private var themeIconView: some View {
        Image(systemName: signal.theme.sfSymbol)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(signal.theme.iconColor)
            .frame(width: 40, height: 40)
            .background(PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }

    // MARK: - Accessibility

    private var a11yLabel: String {
        if let verdict = signal.verdictKind {
            return "\(signal.theme.displayName) 테마, 보유비중 \(signal.myExposurePercent)%, \(verdict.sentimentLabel)"
        }
        return "\(signal.theme.displayName) 테마, 보유비중 \(signal.myExposurePercent)%, 이번 주 특이 신호 없음"
    }

    private var a11yHint: String {
        guard signal.verdictKind != nil else { return "" }
        return isExpanded ? "두 번 탭하면 접힙니다" : "두 번 탭하면 자세히 볼 수 있습니다"
    }
}

// MARK: - ThemeExpansionContent

/// 카드 펼침 시 노출되는 처방 영역.
/// SentimentPill + 상황 요약 + 처방 블록 + Signal 이동 링크로 구성.
private struct ThemeExpansionContent: View {
    let verdict: PolSignalVerdictKind
    let prescription: TodayDecisionPrescription
    let narrativeState: NarrativeLoadState
    let onRetry: () -> Void
    let onFullAnalysis: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ① 상태 배지
            SentimentPill(kind: verdict)

            // ② 상황 요약 (평어, 최대 2줄)
            Text(prescription.summary)
                .font(.pretendard(13, weight: .regular, relativeTo: .footnote))
                .foregroundStyle(PSColor.textSecondary)
                .lineLimit(2)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // ③ 처방 블록
            prescriptionBlock

            // ④ 백엔드 내러티브
            NarrativeContentView(
                narrative: prescription.narrative,
                loadState: narrativeState,
                onRetry: onRetry
            )

            // ⑤ Signal 탭 이동 링크
            Button(action: onFullAnalysis) {
                HStack(spacing: 4) {
                    Text("왜 그런지 알아보기")
                        .font(.pretendard(13, weight: .semibold, relativeTo: .footnote))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(PSColor.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(
            verdict.sentimentSoft.opacity(0.6),
            in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous)
                .stroke(verdict.sentimentForeground.opacity(0.18), lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var prescriptionBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(verdict.prescriptionIconColor)
                .padding(.top, 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(prescription.action)
                    .font(.pretendard(15, weight: .bold, relativeTo: .body))
                    .foregroundStyle(PSColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                if let nowPercent = prescription.nowPercent {
                    HStack(spacing: 10) {
                        Text("지금 \(nowPercent)")
                            .font(.pretendard(12, weight: .medium, relativeTo: .caption).monospacedDigit())
                            .foregroundStyle(PSColor.textSecondary)

                        if let goalLabel = prescription.goalLabel {
                            Text("→")
                                .font(.pretendard(13, weight: .semibold, relativeTo: .footnote))
                                .foregroundStyle(PSColor.textFaint)
                                .accessibilityHidden(true)

                            Text(goalLabel)
                                .font(.pretendard(12, weight: .semibold, relativeTo: .caption).monospacedDigit())
                                .foregroundStyle(PSColor.primary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            verdict.sentimentSoft,
            in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous)
        )
    }
}

// MARK: - ThemeEmptyStateBlock

/// 신호 없음 상태의 안심 메시지 블록.
/// 카드가 탭 불가 상태일 때 헤더 아래에 항상 노출된다.
private struct ThemeEmptyStateBlock: View {
    let signal: PortfolioThemeSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PSColor.textFaint)
                    .accessibilityHidden(true)

                Text("이번 주 특이 신호 없음")
                    .font(.pretendard(13, weight: .semibold, relativeTo: .footnote))
                    .foregroundStyle(PSColor.textSecondary)
            }

            Text("\(signal.theme.displayName) 관련 주요 뉴스가 없는 조용한 한 주예요.")
                .font(.pretendard(12, weight: .regular, relativeTo: .caption))
                .foregroundStyle(PSColor.textFaint)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let nextEventLabel = signal.nextEventLabel {
                Text("다음 체크: \(nextEventLabel)")
                    .font(.pretendard(11, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(PSColor.primary)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous)
                .stroke(PSColor.border, lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
        .padding(.top, 6)
    }
}

// MARK: - NarrativeContentView

/// 백엔드에서 받은 내러티브 텍스트를 상태에 따라 렌더링한다.
/// 로딩 중: shimmer 3줄 / 완료: 텍스트 fade-in / 실패: 재시도 버튼
private struct NarrativeContentView: View {
    let narrative: String?
    let loadState: NarrativeLoadState
    let onRetry: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch loadState {
        case .idle:
            EmptyView()

        case .loading:
            VStack(alignment: .leading, spacing: 8) {
                shimmerLine(fraction: 1.0)
                shimmerLine(fraction: 1.0)
                shimmerLine(fraction: 0.55)
            }
            .padding(.top, 4)

        case .loaded:
            if let text = narrative {
                Text(text)
                    .font(.pretendard(13, weight: .regular, relativeTo: .footnote))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .move(edge: .bottom))
                    )
                    .padding(.top, 4)
            }

        case .error:
            Button(action: onRetry) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("다시 불러오기")
                        .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
                }
                .foregroundStyle(PSColor.textSecondary)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func shimmerLine(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            ShimmerView()
                .frame(width: geo.size.width * fraction, height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .frame(height: 12)
    }
}

// MARK: - ShimmerView

private struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: PSColor.rule, location: 0.0),
                    .init(color: PSColor.surfaceAlt, location: 0.4),
                    .init(color: PSColor.rule, location: 0.6),
                    .init(color: PSColor.rule, location: 1.0)
                ],
                startPoint: UnitPoint(x: phase, y: 0),
                endPoint: UnitPoint(x: phase + 1, y: 0)
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("신호 있음 — 대응") {
    ScrollView {
        ThemeSignalSection(
            signals: PolSignalFlowMockData.todayThemeSignals,
            onFullAnalysis: { _ in }
        )
        .padding(20)
    }
    .background(PSColor.background)
}

#Preview("신호 없음") {
    ThemeSignalCard(
        signal: PortfolioThemeSignal(
            id: UUID(),
            theme: .greenEnergy,
            myExposurePercent: 0,
            verdictKind: nil,
            prescription: nil,
            nextEventLabel: nil,
            relatedEventId: nil
        ),
        isExpanded: false,
        onTap: {},
        onFullAnalysis: {}
    )
    .padding(20)
    .background(PSColor.background)
}
