import SwiftUI

struct PolSignalPolicyReaderView: View {
    let event: PolSignalPolicyReading

    @State private var isRead = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                readerSection(number: "1", title: "무슨 일이에요") {
                    Text(event.whatHappened)
                        .font(.pretendard(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                readerSection(
                    number: "2",
                    title: "AI가 3줄로 정리했어요",
                    iconName: "sparkles",
                    trailingBadge: "AI",
                    isHighlighted: true
                ) {
                    aiSummaryList
                }

                readerSection(number: "3", title: "내 키워드와 이렇게 연결돼요") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("선택한 키워드를 기준으로 이 뉴스가 뜬 이유예요.")
                            .font(.pretendard(12, weight: .regular, relativeTo: .caption))
                            .foregroundStyle(PSColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 10) {
                            ForEach(event.keywordLinks) { link in
                                keywordLinkRow(link)
                            }
                        }
                    }
                }

                readerSection(
                    number: "4",
                    title: "더 알아볼 수 있어요",
                    iconName: "safari",
                    usesNeutralBackground: true
                ) {
                    followUpRows
                }

                actionArea
            }
            .padding(.horizontal, PSSpacing.screenHorizontal)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .background(PSColor.Reader.surface.ignoresSafeArea())
        .navigationTitle("뉴스 읽기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PSColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("북마크")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalFlowLayout(spacing: 6) {
                ForEach(event.keywords, id: \.self) { keyword in
                    PolSignalReaderKeywordChip(text: "#\(keyword)")
                }

                Text("· \(event.institution)")
                    .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(PSColor.textSecondary)

                Text("· \(event.date)")
                    .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(PSColor.textSecondary)
            }

            Text(event.title)
                .font(.pretendard(26, weight: .bold, relativeTo: .title))
                .foregroundStyle(PSColor.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Label("읽기 약 \(event.readMinutes)분", systemImage: "clock")
                .font(.pretendard(13, weight: .medium, relativeTo: .caption))
                .foregroundStyle(PSColor.textSecondary)
        }
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PSColor.Reader.border)
                .frame(height: 1)
                .offset(y: 18)
        }
    }

    private var aiSummaryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(event.aiSummary.enumerated()), id: \.offset) { _, summary in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(PSColor.primary)
                        .frame(width: 5, height: 5)
                        .padding(.top, 8)

                    Text(summary)
                        .font(.pretendard(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var followUpRows: some View {
        VStack(spacing: 8) {
            ForEach(Array(event.followUps.enumerated()), id: \.offset) { _, question in
                Button {} label: {
                    HStack(alignment: .center, spacing: 12) {
                        Text(question)
                            .font(.pretendard(14, weight: .medium, relativeTo: .body))
                            .foregroundStyle(PSColor.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(PSColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 46)
                    .padding(.horizontal, 12)
                    .background(PSColor.Reader.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(question)
            }
        }
    }

    private func readerSection<Content: View>(
        number: String,
        title: String,
        iconName: String? = nil,
        trailingBadge: String? = nil,
        isHighlighted: Bool = false,
        usesNeutralBackground: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.pretendard(13, weight: .bold, relativeTo: .caption))
                .foregroundStyle(isHighlighted ? Color.white : PSColor.Reader.lensText)
                .frame(width: 28, height: 28)
                .background(isHighlighted ? PSColor.primary : PSColor.Reader.lensBg, in: Circle())
                .overlay {
                    Circle()
                        .stroke(isHighlighted ? PSColor.primary : PSColor.Reader.lensBorder, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 6) {
                    if let iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                    }

                    Text(title)
                        .font(.pretendard(17, weight: .semibold, relativeTo: .headline))
                        .foregroundStyle(PSColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 6)

                    if let trailingBadge {
                        Text(trailingBadge)
                            .font(.pretendard(11, weight: .bold, relativeTo: .caption))
                            .foregroundStyle(PSColor.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(PSColor.Reader.surface, in: Capsule(style: .continuous))
                    }
                }

                content()
            }
            .padding((isHighlighted || usesNeutralBackground) ? 14 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                sectionBackground(isHighlighted: isHighlighted, usesNeutralBackground: usesNeutralBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: "DBE6FE"), lineWidth: 1)
                }
            }
        }
    }

    private func sectionBackground(isHighlighted: Bool, usesNeutralBackground: Bool) -> Color {
        if isHighlighted {
            return PSColor.primarySoft
        }

        if usesNeutralBackground {
            return PSColor.surfaceAlt
        }

        return .clear
    }

    private func keywordLinkRow(_ link: PolSignalPolicyKeywordLink) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("#\(link.kw)")
                .font(.pretendard(12, weight: .bold, relativeTo: .caption))
                .foregroundStyle(PSColor.primary)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(PSColor.primarySoft, in: Capsule(style: .continuous))
                .fixedSize()

            Text(link.why)
                .font(.pretendard(14, weight: .regular, relativeTo: .body))
                .foregroundStyle(PSColor.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(PSColor.Reader.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PSColor.Reader.border, lineWidth: 1)
        }
    }

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {} label: {
                HStack(spacing: 6) {
                    Text("이 키워드 다른 뉴스 보기")
                        .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(PSColor.primary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(PSColor.Reader.surface, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous)
                        .stroke(PSColor.Reader.lensBorder, lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("이 키워드 다른 뉴스 보기")

            Button {
                isRead.toggle()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: isRead ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("읽었어요 ✓")
                        .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(PSColor.primary, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: isRead)
            .accessibilityLabel("읽었어요")
            .accessibilityValue(isRead ? "완료" : "미완료")

            Text("완료 표시는 기록에만 사용돼요.")
                .font(.pretendard(12, weight: .regular, relativeTo: .caption))
                .foregroundStyle(PSColor.textFaint)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
