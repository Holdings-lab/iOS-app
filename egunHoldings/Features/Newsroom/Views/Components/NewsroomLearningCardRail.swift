import SwiftUI

/// "이걸 이해하려면" 가로 스크롤 카드 (§1.5). 독립 피드가 아니라
/// 오늘 다이제스트의 개념 태그와 매칭되는 학습 콘텐츠를 최대 3장 페어링한다.
/// 탭 → push가 아니라 시트 (브리핑 흐름에서 이탈하지 않도록).
struct NewsroomLearningCardRail: View {
    let items: [NewsroomLearningContent]
    let onSelect: (NewsroomLearningContent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이걸 이해하려면")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            NewsroomLearningRailCard(item: item)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct NewsroomLearningRailCard: View {
    let item: NewsroomLearningContent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: item.heroSystemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(item.category.color)
                .frame(width: 36, height: 36)
                .background(item.category.color.opacity(0.12), in: Circle())

            Text(item.title)
                .font(.pretendard(13.5, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.readTimeText)
                .font(.pretendard(10.5, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(Color.muted, in: Capsule())
        }
        .padding(12)
        .frame(width: 156, alignment: .topLeading)
        .frame(minHeight: 148, alignment: .topLeading)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

/// 학습 카드 상세 시트. 본문 + "관련된 오늘 소식" 역링크 1개.
struct NewsroomLearningCardDetailSheet: View {
    let item: NewsroomLearningContent
    let relatedDigest: NewsroomDetailContent?
    let onOpenRelatedDigest: (NewsroomDetailContent) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: item.heroSystemImage)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(item.category.color)
                            .frame(width: 42, height: 42)
                            .background(item.category.color.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.category.title)
                                .font(.pretendard(11, weight: .bold))
                                .foregroundStyle(item.category.color)

                            Text(item.readTimeText)
                                .font(.pretendard(11, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                        }

                        Spacer()
                    }

                    Text(item.title)
                        .font(.pretendard(22, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.summary)
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    if let relatedDigest {
                        relatedDigestLink(relatedDigest)
                    }
                }
                .padding(20)
            }
            .background(Color.canvas.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func relatedDigestLink(_ content: NewsroomDetailContent) -> some View {
        Button {
            dismiss()
            onOpenRelatedDigest(content)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("관련된 오늘 소식")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.textTertiary)

                    Text(relatedDigestTitle(content))
                        .font(.pretendard(13.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.textQuaternary)
            }
            .padding(14)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func relatedDigestTitle(_ content: NewsroomDetailContent) -> String {
        switch content {
        case .ticker(let digest):
            return digest.headline ?? digest.name
        case .marketStory(let story, _):
            return story.headline
        }
    }
}
