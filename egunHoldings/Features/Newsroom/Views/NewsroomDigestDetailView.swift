import SwiftUI

/// 리스트 페이로드만으로 그리는 종목 상세. 별도 네트워크 요청이나 로딩 상태가 없다.
struct NewsroomDigestDetailView: View {
    let digest: NewsroomTickerDigest
    let referenceText: String

    @Environment(\.dismiss) private var dismiss
    @State private var isTitleVisible = false
    @State private var presentedArticle: NewsroomSafariDestination?

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        assetHeader

                        Divider()
                            .overlay(Color.hairline)
                            .padding(.vertical, 18)

                        Text(digest.headline ?? digest.name)
                            .font(.pretendard(23, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        representativeImage
                            .padding(.top, 18)

                        if let aiView = digest.aiView {
                            NewsroomAIJudgmentSection(text: aiView)
                                .padding(.top, 24)
                        }

                        if digest.summary != nil || !digest.newFacts.isEmpty {
                            summarySection
                                .padding(.top, 26)
                        }

                        if !digest.articles.isEmpty {
                            sourcesSection
                                .padding(.top, 28)
                        }

                        footer
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, KDXSpacing.tabBarHeight + 16)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    isTitleVisible = newValue > 64
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $presentedArticle) { destination in
            NewsroomSafariView(url: destination.url)
                .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            LiquidGlassBackButton(action: { dismiss() })

            Spacer()

            Text(digest.ticker)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .opacity(isTitleVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.16), value: isTitleVisible)

            Spacer()

            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.canvas.opacity(0.96))
    }

    private var assetHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            NewsroomTickerLogo(digest: digest, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(digest.ticker)
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(digest.name)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }

                if let priceChange = digest.priceChangePercent {
                    Text("오늘 \(NewsroomPercentFormat.signed(priceChange))")
                        .font(.pretendard(26, weight: .bold))
                        .foregroundStyle(NewsroomPercentFormat.color(for: priceChange))
                        .monospacedDigit()
                }

                if let impact = digest.portfolioImpactPercent {
                    Text("내 자산의 \(digest.portfolioWeightPercent)% · 총자산 기준 \(NewsroomPercentFormat.signedImpact(impact))")
                        .font(.pretendard(12.5, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }

                Text(referenceText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
                    .padding(.top, 2)
            }
        }
    }

    private var representativeImage: some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                if let imageURL = digest.representativeImageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            imageFallback
                        }
                    }
                } else {
                    imageFallback
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .background(Color.muted)
            .clipShape(RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .clipped()

            if let attribution = digest.imageAttribution, digest.representativeImageURL != nil {
                Text("사진: \(attribution)")
                    .font(.pretendard(10.5, weight: .medium))
                    .foregroundStyle(Color.textQuaternary)
            }
        }
    }

    private var imageFallback: some View {
        VStack(spacing: 10) {
            NewsroomTickerLogo(digest: digest, size: 72)
            Text(digest.name)
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brandTintBg.opacity(0.6))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let summary = digest.summary {
                Text(summary)
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !digest.newFacts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("새로 알려진 내용")
                        .font(.pretendard(14.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    ForEach(Array(digest.newFacts.enumerated()), id: \.offset) { _, fact in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.pretendard(14, weight: .bold))
                                .foregroundStyle(Color.textTertiary)

                            Text(fact)
                                .font(.pretendard(14.5, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("출처")
                .font(.pretendard(14.5, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(digest.articles.enumerated()), id: \.element.id) { index, article in
                    if index > 0 {
                        Divider().overlay(Color.hairline)
                    }

                    Button {
                        if let url = article.url {
                            presentedArticle = NewsroomSafariDestination(url: url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(article.title)
                                    .font(.pretendard(14, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(article.source) · \(NewsroomDigestDateFormat.relativeText(for: article.publishedAt))")
                                    .font(.pretendard(11, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }

                            Spacer(minLength: 4)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.textQuaternary)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(article.url == nil)
                }
            }
            .padding(.horizontal, 14)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
    }

    private var footer: some View {
        Text("\(referenceText) · AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요.")
            .font(.pretendard(11, weight: .medium))
            .foregroundStyle(Color.textTertiary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// AI판단 섹션 전용 뷰. 화면 진입 시 1회성으로만 나타난다 — 루프 애니메이션이나
/// 타자기 효과는 쓰지 않는다: 이 콘텐츠는 전날 배치로 이미 생성돼 캐시된 것이라,
/// "지금 실시간으로 생성 중"처럼 보이는 연출은 §5 날짜 정직성 원칙과 충돌한다.
/// 아이콘의 스케일 팝도 등장 시 한 번만 재생되고 끝난다(반복 반짝임 금지, §3.5).
private struct NewsroomAIJudgmentSection: View {
    let text: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .scaleEffect(hasAppeared ? 1 : 0.78)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.72),
                        value: hasAppeared
                    )
                Text("AI는 이렇게 판단했어요")
                    .font(.pretendard(14.5, weight: .bold))
            }
            .foregroundStyle(Color.brand)

            Text(text)
                .font(.pretendard(14.5, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("본 내용은 투자 판단의 근거가 아닙니다.")
                .font(.pretendard(10.5, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(15)
        .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .opacity(hasAppeared ? 1 : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: hasAppeared)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
        }
    }
}

#Preview {
    NavigationStack {
        NewsroomDigestDetailView(
            digest: NewsroomDigestMockData.calmMixed.tickerDigests[0],
            referenceText: NewsroomDigestMockData.calmMixed.referenceText
        )
    }
}
