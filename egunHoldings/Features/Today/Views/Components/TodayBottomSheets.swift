import SwiftUI

// MARK: - Sheet Background

private struct SheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.elevated)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)
            }
    }
}

private extension View {
    func sheetBackground() -> some View { modifier(SheetBackground()) }
}

private struct SheetDragIndicator: View {
    var body: some View {
        Capsule()
            .fill(Color(hex: "E5E7EB"))
            .frame(width: 40, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

// MARK: - SettingsSheet

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let connectedBrokerText: String

    private var items: [(icon: String, title: String, sub: String)] {
        [
            ("person.circle", "계정 정보", "투자자님"),
            ("bell", "알림 설정", "3개 활성화"),
            ("building.columns", "증권사 연결 관리", connectedBrokerText),
            ("chart.bar", "데이터 출처", "정책 브리핑 예시"),
            ("info.circle", "투자 추천 아님 안내", "")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                Text("설정")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(PSColor.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PSColor.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    PSGlassCard(variant: .secondary, padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(items.indices, id: \.self) { i in
                                let item = items[i]
                                HStack(spacing: 12) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(PSColor.electricBlue)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(PSFont.semibold(14))
                                            .foregroundStyle(PSColor.textPrimary)
                                        if !item.sub.isEmpty {
                                            Text(item.sub)
                                                .font(PSFont.caption())
                                                .foregroundStyle(PSColor.textMuted)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(PSColor.textFaint)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)

                                if i < items.count - 1 {
                                    Divider()
                                        .background(PSColor.border)
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button(action: {}) {
                        Text("로그아웃")
                            .font(PSFont.semibold(15))
                            .foregroundStyle(Color.up)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.upBg, in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous))
                    }
                    .buttonStyle(PSPressStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheetBackground()
    }
}

// MARK: - DataStatusSheet

struct DataStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    let rows: [(String, String)]
    let connectionStatusText: String
    let footnote: String

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                Text("데이터 상태")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(PSColor.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PSColor.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            PSGlassCard(variant: .primary) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                            .foregroundStyle(PSColor.emerald)
                        Text("연결 상태")
                            .font(PSFont.semibold(14))
                            .foregroundStyle(PSColor.textPrimary)
                        Spacer()
                        Text(connectionStatusText)
                            .font(PSFont.semibold(12))
                            .foregroundStyle(PSColor.emerald)
                    }

                    VStack(spacing: 0) {
                        ForEach(rows.indices, id: \.self) { i in
                            HStack {
                                Text(rows[i].0)
                                    .font(PSFont.caption())
                                    .foregroundStyle(PSColor.textMuted)
                                Spacer()
                                Text(rows[i].1)
                                    .font(PSFont.semibold(12))
                                    .foregroundStyle(PSColor.textPrimary)
                            }
                            .padding(.vertical, 10)

                            if i < rows.count - 1 {
                                Divider().background(PSColor.border)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(PSColor.textFaint)
                Text(footnote)
                    .font(PSFont.caption())
                    .foregroundStyle(PSColor.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .sheetBackground()
    }
}

// MARK: - QuickReasonSheet

struct QuickReasonSheet: View {
    let judgment: TodayJudgment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                Text("판단 근거")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(PSColor.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PSColor.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    PSGlassCard(variant: .primary) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("핵심 근거")
                                .font(PSFont.semibold(12))
                                .foregroundStyle(PSColor.electricBlue.opacity(0.60))

                            ForEach(judgment.forEvidence, id: \.self) { ev in
                                evidenceRow(text: ev, icon: "checkmark.circle.fill", color: PSColor.emerald)
                            }
                        }
                    }

                    PSGlassCard(variant: .secondary) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("반대 근거")
                                .font(PSFont.semibold(12))
                                .foregroundStyle(PSColor.yellow.opacity(0.60))

                            ForEach(judgment.againstEvidence, id: \.self) { ev in
                                evidenceRow(text: ev, icon: "exclamationmark.circle.fill", color: PSColor.yellow)
                            }
                        }
                    }

                    PSGlassCard(variant: .secondary) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("정책 전달 경로")
                                .font(PSFont.semibold(12))
                                .foregroundStyle(PSColor.textMuted.opacity(0.40))
                            Text(judgment.deliveryPath)
                                .font(PSFont.body(13))
                                .foregroundStyle(PSColor.textPrimary.opacity(0.70))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                    }

                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "shield")
                            .font(.system(size: 11))
                            .foregroundStyle(PSColor.textFaint)
                        Text("이 판단은 정보 제공 목적이며 투자 추천이 아닙니다.")
                            .font(PSFont.caption())
                            .foregroundStyle(PSColor.textFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheetBackground()
    }

    private func evidenceRow(text: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .padding(.top, 1)
            Text(text)
                .font(PSFont.body(13))
                .foregroundStyle(PSColor.textPrimary.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }
}

// MARK: - SaveCheckpointSheet

struct SaveCheckpointSheet: View {
    @Environment(\.dismiss) private var dismiss
    let conditionText: String
    @State private var importance: PSImportance = .high
    @State private var alertTime: Int = 0

    private let alertOptions = ["장 시작 전 (오전 9:00)", "장 마감 1시간 전", "즉시 알림"]

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                Text("체크포인트 저장")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(PSColor.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PSColor.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    PSGlassCard(variant: .secondary) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("저장할 조건")
                                .font(PSFont.semibold(12))
                                .foregroundStyle(PSColor.textMuted)
                            Text(conditionText)
                                .font(PSFont.semibold(14))
                                .foregroundStyle(PSColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("중요도")
                            .font(PSFont.semibold(13))
                            .foregroundStyle(PSColor.textPrimary)
                            .padding(.horizontal, 20)

                        HStack(spacing: 8) {
                            ForEach(PSImportance.allCases, id: \.rawValue) { level in
                                importanceSegment(level)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("알림 시간")
                            .font(PSFont.semibold(13))
                            .foregroundStyle(PSColor.textPrimary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            ForEach(alertOptions.indices, id: \.self) { i in
                                alertRow(index: i)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    PSGradientButton(label: "저장") { dismiss() }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .sheetBackground()
    }

    private func importanceSegment(_ level: PSImportance) -> some View {
        let isSelected = importance == level
        return Button { importance = level } label: {
            Text(level.rawValue)
                .font(PSFont.semibold(13))
                .foregroundStyle(isSelected ? PSColor.electricBlue : PSColor.textMuted.opacity(0.50))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? PSColor.electricBlue.opacity(0.15)
                        : Color.muted,
                    in: RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous)
                        .stroke(
                            isSelected ? PSColor.electricBlue.opacity(0.30) : PSColor.border,
                            lineWidth: isSelected ? 1 : 0.5
                        )
                }
        }
        .buttonStyle(PSPressStyle())
    }

    private func alertRow(index: Int) -> some View {
        let isSelected = alertTime == index
        return Button { alertTime = index } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? PSColor.electricBlue : PSColor.border, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(PSColor.electricBlue)
                            .frame(width: 10, height: 10)
                    }
                }
                Text(alertOptions[index])
                    .font(PSFont.semibold(13))
                    .foregroundStyle(isSelected ? PSColor.textPrimary : PSColor.textMuted)
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                isSelected ? Color.subtle : Color.clear,
                in: RoundedRectangle(cornerRadius: PSRadius.small, style: .continuous)
            )
        }
        .buttonStyle(PSPressStyle())
    }
}

extension PSImportance: CaseIterable {
    static var allCases: [PSImportance] { [.high, .medium, .low] }
}

// MARK: - SnoozeSheet

struct SnoozeSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let options: [(String, String)] = [
        ("1시간 후", "오후 12:30"),
        ("장 마감 전", "오후 3:00"),
        ("내일 아침", "오전 8:30")
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                Text("나중에 보기")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(PSColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            VStack(spacing: 10) {
                ForEach(options, id: \.0) { option in
                    Button { dismiss() } label: {
                        PSGlassCard(variant: .secondary, padding: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(option.0)
                                        .font(PSFont.semibold(14))
                                        .foregroundStyle(PSColor.textPrimary)
                                    Text(option.1)
                                        .font(PSFont.caption())
                                        .foregroundStyle(PSColor.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(PSColor.textFaint)
                            }
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: PSRadius.card, style: .continuous))
                    .buttonStyle(PSPressStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .sheetBackground()
    }
}

// MARK: - PolicyDetailSheet

struct PolicyDetailSheet: View {
    let policy: TodayPolicyEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack(alignment: .center, spacing: 10) {
                PolicyColorDot(color: policy.color, size: 8)
                Text(policy.title)
                    .font(PSFont.semibold(18))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    PSGlassCard(variant: .primary) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                PSStatusChip(label: policy.dDay, color: Color.brand)
                                PSStatusChip(label: policy.status.rawValue, color: policy.status.color)
                                Spacer()
                                Text("내 자산 \(policy.myExposure)% 관련")
                                    .font(PSFont.semibold(12))
                                    .foregroundStyle(Color.brand)
                            }

                            Text(policy.summary)
                                .font(PSFont.body(14))
                                .foregroundStyle(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                    }

                    PSGlassCard(variant: .secondary) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("확인 근거")
                                .font(PSFont.semibold(13))
                                .foregroundStyle(Color.textPrimary)

                            ForEach(policy.evidence, id: \.self) { evidence in
                                policyEvidenceRow(evidence, icon: "checkmark.circle.fill", color: Color.brand)
                            }

                            policyEvidenceRow(policy.counterEvidence, icon: "exclamationmark.circle.fill", color: Color.warning)
                        }
                    }

                    if !policy.invalidationConditions.isEmpty {
                        PSGlassCard(variant: .secondary) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("다시 볼 조건")
                                    .font(PSFont.semibold(13))
                                    .foregroundStyle(Color.warning)

                                ForEach(policy.invalidationConditions, id: \.self) { condition in
                                    policyEvidenceRow(condition, icon: "clock", color: Color.warning)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheetBackground()
    }

    private func policyEvidenceRow(_ text: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .padding(.top, 1)
            Text(text)
                .font(PSFont.body(13))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }
}

// MARK: - PolicyListSheet

struct PolicyListSheet: View {
    let policies: [TodayPolicyEvent]
    let onSelect: (TodayPolicyEvent) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                Text("오늘 정책")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(policies) { policy in
                        Button {
                            onSelect(policy)
                        } label: {
                            PSGlassCard(variant: .secondary, padding: 14) {
                                HStack(spacing: 10) {
                                    PolicyColorDot(color: policy.color)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(policy.title)
                                            .font(PSFont.semibold(14))
                                            .foregroundStyle(Color.textPrimary)
                                            .lineLimit(1)
                                        Text("내 자산 중 \(policy.myExposure)% 관련")
                                            .font(PSFont.caption())
                                            .foregroundStyle(Color.textTertiary)
                                    }
                                    Spacer()
                                    ImpactDotsForSheet(score: min(5, max(1, (policy.myExposure + 19) / 20)))
                                }
                            }
                        }
                        .buttonStyle(PSPressStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheetBackground()
    }
}

private struct ImpactDotsForSheet: View {
    let score: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= score ? Color.brand : Color.divider)
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - ExposureThemeSheet

struct ExposureThemeSheet: View {
    let item: TodayExposureItem
    let holdings: [TodayHolding]
    let relatedPolicies: [TodayPolicyEvent]
    @Environment(\.dismiss) private var dismiss

    private var linkedHoldings: [TodayHolding] {
        holdings.filter { h in
            h.exposedThemes.contains { $0.theme == item.theme }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetDragIndicator()

            HStack {
                PolicyColorDot(color: item.color, size: 8)
                Text("\(item.theme) 노출 상세")
                    .font(PSFont.semibold(18))
                    .foregroundStyle(PSColor.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PSColor.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    PSGlassCard(variant: .primary) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(item.theme) 테마에 노출된 보유 자산")
                                .font(PSFont.semibold(13))
                                .foregroundStyle(item.color.opacity(0.80))

                            if linkedHoldings.isEmpty {
                                Text("연결된 보유 자산이 없어요")
                                    .font(PSFont.body(13))
                                    .foregroundStyle(PSColor.textMuted)
                            } else {
                                ForEach(linkedHoldings) { holding in
                                    HStack {
                                        PolicyColorDot(color: holding.color)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(holding.name)
                                                .font(PSFont.semibold(14))
                                                .foregroundStyle(PSColor.textPrimary)
                                            Text(holding.category)
                                                .font(PSFont.caption())
                                                .foregroundStyle(PSColor.textMuted)
                                        }
                                        Spacer()
                                        Text("\(holding.weight)%")
                                            .font(PSFont.semibold(14))
                                            .foregroundStyle(item.color)
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                    }

                    if !relatedPolicies.isEmpty {
                        PSGlassCard(variant: .secondary) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("관련 정책")
                                    .font(PSFont.semibold(13))
                                    .foregroundStyle(PSColor.textMuted)

                                ForEach(relatedPolicies.prefix(3)) { policy in
                                    HStack(spacing: 8) {
                                        PolicyColorDot(color: policy.color)
                                        Text(policy.title)
                                            .font(PSFont.semibold(13))
                                            .foregroundStyle(PSColor.textPrimary)
                                        Spacer()
                                        Text(policy.dDay)
                                            .font(PSFont.caption())
                                            .foregroundStyle(PSColor.textMuted)
                                    }
                                }
                            }
                        }
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "bookmark.badge.plus")
                                .font(.system(size: 13, weight: .medium))
                            Text("체크포인트로 저장")
                                .font(PSFont.semibold(14))
                        }
                        .foregroundStyle(PSColor.electricBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PSColor.electricBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: PSRadius.inner, style: .continuous))
                    }
                    .buttonStyle(PSPressStyle())
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheetBackground()
    }
}
