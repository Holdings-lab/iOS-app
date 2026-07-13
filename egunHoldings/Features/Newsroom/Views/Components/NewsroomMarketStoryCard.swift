import SwiftUI

/// 시장 공통 스토리 카드 (§1.3). 여러 종목에 걸치는 매크로 이슈를
/// 종목 다이제스트에 중복 배포하지 않고 1장으로 정리한다. 없으면 섹션 자체를 숨긴다.
struct NewsroomMarketStoryCard: View {
    let story: NewsroomMarketStory
    let onOpenDetail: () -> Void

    @State private var isStorylineExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpenDetail) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("시장 공통")
                                .font(.pretendard(10, weight: .bold))
                        }
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 9)
                        .frame(height: 25)
                        .background(Color.brandTintBg, in: Capsule(style: .continuous))

                        Spacer(minLength: 4)

                        Text(NewsroomDigestDateFormat.referenceText(for: story.updatedAt))
                            .font(.pretendard(10.5, weight: .semibold))
                            .foregroundStyle(Color.textQuaternary)
                            .lineLimit(1)
                    }

                    Text(story.headline)
                        .font(.pretendard(17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(story.summary)
                        .font(.pretendard(13.5, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .buttonStyle(PressScaleButtonStyle())

            if let storyline = story.storyline {
                storylineDisclosure(storyline)
            }
        }
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func storylineDisclosure(_ storyline: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isStorylineExpanded.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Text("지금까지의 줄거리 보기")
                        .font(.pretendard(11.5, weight: .bold))
                    Image(systemName: isStorylineExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)

            if isStorylineExpanded {
                Text(storyline)
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.muted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
