import SwiftUI

struct SignupTermsView: View {
    let items: [SignupConsentDefinition]
    let selectedIDs: Set<String>
    let onBack: () -> Void
    let onToggleAll: () -> Void
    let onToggleItem: (String) -> Void
    let onNext: () -> Void

    @State private var presentedItem: SignupConsentDefinition?

    private var allSelected: Bool {
        items.allSatisfy { selectedIDs.contains($0.id) }
    }

    private var canContinue: Bool {
        items.filter(\.isRequired).allSatisfy { selectedIDs.contains($0.id) }
    }

    private var groupedItems: [ConsentListItem] {
        items.map {
            ConsentListItem(
                id: $0.id,
                title: $0.title,
                summary: $0.summary,
                isRequired: $0.isRequired,
                isChecked: selectedIDs.contains($0.id)
            )
        }
    }

    var body: some View {
        PFContentScrollView(
            alignment: .leading,
            spacing: MidnightLayout.majorGap,
            horizontalPadding: MidnightLayout.horizontal,
            topPadding: 16,
            bottomPadding: 120
        ) {
            FlowProgressHeader(currentStep: 1, totalSteps: 4, stepTitle: "계정 만들기 · 약관", onBack: onBack)

            VStack(alignment: .leading, spacing: 10) {
                Text("필수 약관을 확인해주세요")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("필수 항목 동의 후 계속할 수 있어요.")
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
            }

            Button(action: onToggleAll) {
                HStack(spacing: 12) {
                    PFSelectionIndicator(isSelected: allSelected, tint: .brand, size: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("전체 동의 (선택 포함)")
                            .font(.pretendard(16, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)

                        Text("필수 약관과 선택 항목을 한 번에 설정할 수 있어요.")
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            GroupedConsentList(
                items: groupedItems,
                onToggle: { item in
                    onToggleItem(item.id)
                },
                onView: { item in
                    presentedItem = items.first(where: { $0.id == item.id })
                }
            )

            if !canContinue {
                InlineFeedbackText(message: "필수 항목에 동의하면 계속할 수 있어요.", tone: .neutral)
            }
        }
        .safeAreaInset(edge: .bottom) {
            FlowPrimaryButton(title: "다음", isEnabled: canContinue, action: onNext)
                .padding(.horizontal, MidnightLayout.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .sheet(item: $presentedItem) { item in
            ConsentDetailSheet(item: item)
        }
        .background(PFGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ConsentDetailSheet: View {
    let item: SignupConsentDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(item.title)
                        .font(.pretendard(24, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(item.detailBody)
                        .font(.pretendard(15, weight: .regular))
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .background(PFGradientBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기", action: { dismiss() })
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .preferredColorScheme(.light)
        .presentationDetents([.medium])
    }
}

#Preview {
    SignupTermsView(
        items: [
            SignupConsentDefinition(id: "service", title: "서비스 이용약관", summary: "서비스 이용 기준을 확인해요.", isRequired: true, detailBody: "약관 전문"),
            SignupConsentDefinition(id: "marketing", title: "혜택 및 이벤트 알림 수신", summary: "새로운 기능과 혜택 소식을 받아볼 수 있어요.", isRequired: false, detailBody: "선택 약관 전문")
        ],
        selectedIDs: ["service"],
        onBack: {},
        onToggleAll: {},
        onToggleItem: { _ in },
        onNext: {}
    )
    .preferredColorScheme(.light)
}
