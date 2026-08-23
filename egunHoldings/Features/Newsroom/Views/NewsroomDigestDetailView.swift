import SwiftUI

/// 종목 상세. 이제 목록 페이로드만으로 그릴 수 없다 — aiJudgement/summary/sources는 서버가
/// 상세 엔드포인트에서만 준다(NewsroomController.getNewsroomDetail). 그래서 자체 네트워크 요청과
/// 로딩 상태를 가진다. 헤더(티커/이름/등락률/비중)만은 목록에서 이미 받은 값으로 즉시 그린다.
struct NewsroomDigestDetailView: View {
    @StateObject private var viewModel: NewsroomTickerDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isTitleVisible = false
    @State private var presentedArticle: NewsroomSafariDestination?

    init(viewModel: NewsroomTickerDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var stock: NewsroomStockMeta {
        viewModel.detail?.stock ?? NewsroomStockMeta(
            ticker: viewModel.holding.ticker,
            name: viewModel.holding.name,
            dailyChangePercent: viewModel.holding.dailyChangePercent,
            weightPercent: viewModel.holding.weightPercent,
            totalAssetImpactPercent: viewModel.holding.totalAssetImpactPercent
        )
    }

    private var headline: String {
        viewModel.detail?.headline ?? viewModel.holding.headline ?? viewModel.holding.name
    }

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

                        Text(headline)
                            .font(.pretendard(23, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        representativeImage
                            .padding(.top, 18)

                        if let detail = viewModel.detail {
                            detailBody(detail)
                        } else if viewModel.isLoading {
                            loadingRow
                                .padding(.top, 24)
                        } else if let errorMessage = viewModel.errorMessage {
                            NewsroomErrorCard(message: errorMessage) {
                                viewModel.load()
                            }
                            .padding(.top, 24)
                        }
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
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private func detailBody(_ detail: NewsroomTickerDetail) -> some View {
        if let aiJudgement = detail.aiJudgement {
            NewsroomAIJudgmentSection(judgement: aiJudgement)
                .padding(.top, 24)
        }

        if detail.summaryBody != nil || !detail.findings.isEmpty {
            summarySection(detail)
                .padding(.top, 26)
        }

        if !detail.sources.isEmpty {
            sourcesSection(detail)
                .padding(.top, 28)
        }

        footer(detail)
            .padding(.top, 20)
    }

    private var topBar: some View {
        HStack {
            LiquidGlassBackButton(action: { dismiss() })

            Spacer()

            Text(stock.ticker)
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
            NewsroomTickerLogo(ticker: stock.ticker, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(stock.ticker)
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(stock.name)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }

                if let dailyChange = stock.dailyChangePercent {
                    Text("오늘 \(NewsroomPercentFormat.signed(dailyChange))")
                        .font(.pretendard(26, weight: .bold))
                        .foregroundStyle(NewsroomPercentFormat.color(for: dailyChange))
                        .monospacedDigit()
                }

                if let weight = stock.weightPercent, let impact = stock.totalAssetImpactPercent {
                    Text("내 자산의 \(NewsroomPercentFormat.weight(weight))% · 총자산 기준 \(NewsroomPercentFormat.signedImpact(impact))")
                        .font(.pretendard(12.5, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private var representativeImage: some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                if let imageURL = viewModel.detail?.imageURL {
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
            .frame(height: 150)
            .background(Color.muted)
            .clipShape(RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
            .clipped()
        }
    }

    private var imageFallback: some View {
        VStack(spacing: 10) {
            NewsroomTickerLogo(ticker: stock.ticker, size: 72)
            Text(stock.name)
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brandTintBg.opacity(0.6))
    }

    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Color.textTertiary)
            Spacer()
        }
        .padding(.vertical, 32)
    }

    private func summarySection(_ detail: NewsroomTickerDetail) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if let summary = detail.summaryBody {
                Text(summary)
                    .font(.pretendard(16, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !detail.findings.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("새로 알려진 내용")
                        .font(.pretendard(14.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    ForEach(Array(detail.findings.enumerated()), id: \.offset) { _, finding in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.pretendard(14, weight: .bold))
                                .foregroundStyle(Color.textTertiary)

                            Text(finding)
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

    private func sourcesSection(_ detail: NewsroomTickerDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("출처")
                .font(.pretendard(14.5, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(detail.sources.enumerated()), id: \.element.id) { index, source in
                    if index > 0 {
                        Divider().overlay(Color.hairline)
                    }

                    Button {
                        if let url = source.url {
                            presentedArticle = NewsroomSafariDestination(url: url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(source.title)
                                    .font(.pretendard(14, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text([source.publisher, source.publishedAtRelativeText].compactMap { $0 }.joined(separator: " · "))
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
                    .disabled(source.url == nil)
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

    private func footer(_ detail: NewsroomTickerDetail) -> some View {
        let notice = detail.aiNotice ?? "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요."
        let text = [detail.asOfAtText, notice].compactMap { $0 }.joined(separator: " · ")

        return Text(text)
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
    let judgement: NewsroomAIJudgement

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @State private var isReasonExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Text(judgement.headline)
                .font(.pretendard(14.5, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if judgement.hasReason {
                reasonDisclosure
            }

            Text(judgement.disclaimerText)
                .font(.pretendard(10.5, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(15)
        .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .opacity(hasAppeared ? 1 : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: hasAppeared)
        .onAppear {
            guard !hasAppeared else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .scaleEffect(hasAppeared ? 1 : 0.78)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.72),
                    value: hasAppeared
                )

            Text(judgement.titleText)
                .font(.pretendard(14.5, weight: .bold))

            Spacer(minLength: 8)

            if let alignment = judgement.alignment {
                Text(alignment.label)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.75), in: Capsule(style: .continuous))
            }
        }
        .foregroundStyle(Color.brand)
    }

    /// 근거 문단은 분량이 커서(모델이 한 문단을 통째로 준다) 기본은 접어 둔다.
    /// 시트로 띄우지 않는 이유는 이 화면 자체가 이미 푸시된 상세라서다 — 결론과 근거를
    /// 같은 화면에서 나란히 읽을 수 있어야 근거가 근거로 기능한다.
    private var reasonDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .overlay(Color.brand.opacity(0.15))

            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    isReasonExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isReasonExpanded ? "판단 근거 접기" : "판단 근거 보기")
                        .font(.pretendard(13, weight: .bold))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(isReasonExpanded ? 180 : 0))

                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color.brand)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isReasonExpanded ? "판단 근거를 접습니다" : "판단 근거를 펼칩니다")

            if isReasonExpanded, let reason = judgement.reason {
                Text(reason)
                    .font(.pretendard(13.5, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewsroomDigestDetailView(
            viewModel: NewsroomTickerDetailViewModel(
                holding: NewsroomDigestMockData.calmMixed.holdings[0],
                repository: MockNewsroomDigestRepository(scenario: .mixed)
            )
        )
    }
}
