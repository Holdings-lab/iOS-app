import SwiftUI

struct PolSignalPolicyReaderView: View {
    let event: PolSignalPolicyReading

    @State private var isUnderstood = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                readerSection(number: "1", title: "무슨 일이 있어요") {
                    Text(event.whatHappened)
                        .font(.pretendard(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(PSColor.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                readerSection(
                    number: "2",
                    title: "이렇게 읽어요",
                    iconName: "sparkles",
                    isHighlighted: true
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("전이되는 렌즈")
                                .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(PSColor.primary)

                            Text(event.readingLens)
                                .font(.pretendard(18, weight: .semibold, relativeTo: .headline))
                                .foregroundStyle(PSColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("이 패턴은 다른 정책 이벤트를 읽을 때도 다시 쓰여요.")
                                .font(.pretendard(12, weight: .regular, relativeTo: .caption))
                                .foregroundStyle(PSColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("이번 적용")
                                .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(PSColor.primary)

                            Text(event.lensApplication)
                                .font(.pretendard(15, weight: .regular, relativeTo: .body))
                                .foregroundStyle(PSColor.textPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                readerSection(number: "3", title: "보통 이런 흐름이에요") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(event.typicalFlow.enumerated()), id: \.offset) { index, flow in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.pretendard(12, weight: .bold, relativeTo: .caption))
                                    .foregroundStyle(PSColor.Reader.lensText)
                                    .frame(width: 22, height: 22)
                                    .background(PSColor.Reader.lensBg, in: Circle())

                                Text(flow)
                                    .font(.pretendard(14, weight: .regular, relativeTo: .body))
                                    .foregroundStyle(PSColor.textPrimary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                relevanceFooter
                actionArea
            }
            .padding(.horizontal, PSSpacing.screenHorizontal)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .background(PSColor.Reader.surface.ignoresSafeArea())
        .navigationTitle("정책 읽기")
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

                Text("· \(event.dDay)")
                    .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(PSColor.textSecondary)
            }

            Text(event.title)
                .font(.pretendard(26, weight: .bold, relativeTo: .title))
                .foregroundStyle(PSColor.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 13, weight: .semibold))
                Text(event.readingLens)
                    .font(.pretendard(13, weight: .semibold, relativeTo: .caption))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(PSColor.Reader.lensText)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(PSColor.Reader.lensBg, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(PSColor.Reader.lensBorder, lineWidth: 1)
            }

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

    private func readerSection<Content: View>(
        number: String,
        title: String,
        iconName: String? = nil,
        isHighlighted: Bool = false,
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
                HStack(spacing: 6) {
                    Text(title)
                        .font(.pretendard(17, weight: .semibold, relativeTo: .headline))
                        .foregroundStyle(PSColor.textPrimary)

                    if let iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                    }
                }

                content()
            }
            .padding(isHighlighted ? 14 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHighlighted ? PSColor.primarySoft : Color.clear,
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

    private var relevanceFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            PolSignalDashedRule()
                .stroke(PSColor.Reader.border, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(height: 1)

            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PSColor.primary)
                Text("내 관심 키워드와 연결돼요")
                    .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                    .foregroundStyle(PSColor.textPrimary)
            }

            PolSignalFlowLayout(spacing: 6) {
                ForEach(event.relevantKeywords, id: \.self) { keyword in
                    PolSignalReaderKeywordChip(text: "#\(keyword)")
                }
            }

            Text("왜 내가 읽어야 하나의 단서예요. 지금 무엇을 해야 한다는 뜻은 아니에요.")
                .font(.pretendard(13, weight: .regular, relativeTo: .footnote))
                .foregroundStyle(PSColor.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            PolSignalDashedRule()
                .stroke(PSColor.Reader.border, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(height: 1)
        }
    }

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {} label: {
                HStack(spacing: 6) {
                    Text("학습 탭에서 이 렌즈 더 보기")
                        .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(PSColor.primary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                isUnderstood.toggle()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: isUnderstood ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("이해했어요")
                        .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(PSColor.primary, in: RoundedRectangle(cornerRadius: PSRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: isUnderstood)
            .accessibilityLabel("이해했어요")
            .accessibilityValue(isUnderstood ? "완료" : "미완료")

            Text("완료 표시는 학습 기록에만 사용돼요.")
                .font(.pretendard(12, weight: .regular, relativeTo: .caption))
                .foregroundStyle(PSColor.textFaint)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
