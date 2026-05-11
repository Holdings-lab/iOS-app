import SwiftUI

struct ConsentListItem: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let isRequired: Bool
    let isChecked: Bool
}

struct GroupedConsentList: View {
    let items: [ConsentListItem]
    let onToggle: (ConsentListItem) -> Void
    let onView: (ConsentListItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                consentRow(item)

                if index < items.count - 1 {
                    Divider()
                        .overlay(Color.divider)
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func consentRow(_ item: ConsentListItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle(item)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    PFSelectionIndicator(isSelected: item.isChecked, tint: .brand, size: 22)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(item.title)
                                .font(.pretendard(15, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)

                            Text(item.isRequired ? "필수" : "선택")
                                .font(.pretendard(11, weight: .semibold))
                                .foregroundStyle(item.isRequired ? Color.warning : Color.textQuaternary)
                        }

                        Text(item.summary)
                            .font(.pretendard(13, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            Button("보기") {
                onView(item)
            }
            .font(.pretendard(13, weight: .semibold))
            .foregroundStyle(Color.textTertiary)
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }
}

#Preview {
    GroupedConsentList(
        items: [
            ConsentListItem(id: "a", title: "서비스 이용약관", summary: "서비스 이용 기준을 확인해요.", isRequired: true, isChecked: true),
            ConsentListItem(id: "b", title: "혜택 및 이벤트 알림 수신", summary: "새로운 기능과 혜택 소식을 받아볼 수 있어요.", isRequired: false, isChecked: false)
        ],
        onToggle: { _ in },
        onView: { _ in }
    )
    .padding(24)
    .background(PFGradientBackground())
}
