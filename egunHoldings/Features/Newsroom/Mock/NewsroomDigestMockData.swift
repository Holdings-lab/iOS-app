import Foundation

/// 뉴스룸 목록/상세 Mock 데이터. 서버 계약(`NewsroomController`/`NewsroomService`)에 맞춰
/// 목록에는 aiJudgement/summary/sources가 없고, 상세를 별도로 요청해야 그 값들이 채워진다.
nonisolated enum NewsroomDigestMockData {
    static let subtitleReady = "다음 업데이트는 내일 아침이에요"
    static let subtitleEmpty = "보유 종목에 중요한 변화만 모았어요"

    private static var asOfAt: Date {
        Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private static func hoursBeforeGeneration(_ hours: Double) -> Date {
        asOfAt.addingTimeInterval(-hours * 3600)
    }

    // MARK: - 목록

    static var calmMixed: NewsroomBriefing {
        NewsroomBriefing(
            title: "뉴스룸",
            asOfAt: asOfAt,
            subtitle: subtitleReady,
            holdings: [
                holding(ticker: "NVDA", name: "NVIDIA", weight: 12, type: .hero,
                        dailyChangePct: 1.8, totalImpactPct: 0.22,
                        headline: nvidiaHeadline, summary: nvidiaSubheadline),
                holding(ticker: "AAPL", name: "Apple", weight: 18, type: .hero,
                        dailyChangePct: -0.6, totalImpactPct: -0.11,
                        headline: appleHeadline, summary: appleSubheadline),
                holding(ticker: "MSFT", name: "Microsoft", weight: 9, type: .compact,
                        dailyChangePct: 0.2, totalImpactPct: 0.02,
                        headline: msftSubheadline, summary: nil),
                quietHolding(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 13)
            ],
            footerMessage: "오늘 브리핑은 여기까지예요",
            emptyState: nil,
            errorState: nil
        )
    }

    static var allQuiet: NewsroomBriefing {
        NewsroomBriefing(
            title: "뉴스룸",
            asOfAt: asOfAt,
            subtitle: subtitleReady,
            holdings: [
                quietHolding(ticker: "QQQ", name: "Invesco QQQ Trust", weight: 35, quietDays: 12),
                quietHolding(ticker: "AAPL", name: "Apple", weight: 18, quietDays: 3),
                quietHolding(ticker: "NVDA", name: "NVIDIA", weight: 12, quietDays: 1)
            ],
            footerMessage: "오늘 브리핑은 여기까지예요",
            emptyState: nil,
            errorState: nil
        )
    }

    /// 보유 종목이 없을 때 서버가 내려주는 emptyState (NewsroomService.emptyTabResponse와 문구 동일).
    static var empty: NewsroomBriefing {
        NewsroomBriefing(
            title: "뉴스룸",
            asOfAt: asOfAt,
            subtitle: subtitleEmpty,
            holdings: [],
            footerMessage: nil,
            emptyState: NewsroomEmptyState(
                code: "NO_CUSTOM_NEWS",
                title: "맞춤 뉴스가 아직 없어요",
                description: "보유 종목을 연결하면 내 자산과 관련된 정책 뉴스를 골라드려요.",
                buttonLabel: "보유자산 연결하기"
            ),
            errorState: nil
        )
    }

    // MARK: - 상세

    static var nvidiaDetail: NewsroomTickerDetail {
        NewsroomTickerDetail(
            stock: NewsroomStockMeta(ticker: "NVDA", name: "NVIDIA", dailyChangePercent: 1.8, weightPercent: 12, totalAssetImpactPercent: 0.22),
            headline: nvidiaHeadline,
            imageURL: nil,
            aiJudgement: NewsroomAIJudgement(
                title: "AI는 이렇게 판단했어요",
                headline: "뉴스 분위기는 긍정적이지만 실적 발표 직후에는 변동성이 커질 수 있는 구간이에요.",
                reason: "머신러닝은 상승 확률 58% 수준의 완만한 신호를 포착하고 있습니다. 데이터센터 매출이 컨센서스를 웃돈 점은 긍정적이지만, 다음 분기 가이던스가 예상 범위 안에 머물러 추가 상향 여지가 제한적입니다. 실적 발표 직후 구간은 차익 실현 물량이 나오기 쉬워 방향성보다 변동성 확대에 무게를 둡니다.",
                alignment: .positive,
                usedNewsURLs: [],
                disclaimer: "본 내용은 투자 판단의 근거가 아닙니다."
            ),
            summaryBody: "엔비디아가 2분기 실적을 발표했어요. 데이터센터 부문 매출이 시장 예상을 웃돌았다는 보도가 이어졌고, 다음 분기 가이던스는 예상 범위 안이었어요.",
            findings: [
                "데이터센터 매출이 시장 컨센서스를 상회했다고 발표",
                "3분기 가이던스는 애널리스트 예상 범위 내로 제시"
            ],
            sources: [
                source(id: "nvda-1", title: "Nvidia tops data center revenue estimates in Q2", publisher: "Reuters", hoursAgo: 7.8),
                source(id: "nvda-2", title: "Nvidia guidance lands in line with expectations", publisher: "Yahoo Finance", hoursAgo: 3.9)
            ],
            asOfAt: asOfAt,
            aiNotice: "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요."
        )
    }

    static var appleDetail: NewsroomTickerDetail {
        NewsroomTickerDetail(
            stock: NewsroomStockMeta(ticker: "AAPL", name: "Apple", dailyChangePercent: -0.6, weightPercent: 18, totalAssetImpactPercent: -0.11),
            headline: appleHeadline,
            imageURL: nil,
            aiJudgement: NewsroomAIJudgement(
                title: "AI는 이렇게 판단했어요",
                headline: "공급망 다변화는 장기 이슈라서 단일 보도만으로 단기 방향을 판단하기는 어려워요.",
                reason: "머신러닝은 상승 확률 49% 수준으로 방향성을 잡지 못하고 있습니다. 인도 생산 비중 확대는 수년 단위로 진행되는 구조적 변화라 단기 주가에 반영되는 폭이 크지 않고, 회사의 공식 발표가 아직 없어 보도 자체의 확실성도 낮은 편입니다.",
                alignment: .mixed,
                usedNewsURLs: [],
                disclaimer: "본 내용은 투자 판단의 근거가 아닙니다."
            ),
            summaryBody: "애플이 인도 내 생산 비중을 늘리는 방안을 검토 중이라는 보도가 있었어요. 회사의 공식 발표는 아직 없어요.",
            findings: ["인도 생산 비중 확대를 검토 중이라는 보도가 나왔어요"],
            sources: [
                source(id: "aapl-1", title: "Apple weighs expanding India production share", publisher: "Reuters", hoursAgo: 11.3)
            ],
            asOfAt: asOfAt,
            aiNotice: "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요."
        )
    }

    static var msftDetail: NewsroomTickerDetail {
        NewsroomTickerDetail(
            stock: NewsroomStockMeta(ticker: "MSFT", name: "Microsoft", dailyChangePercent: 0.2, weightPercent: 9, totalAssetImpactPercent: 0.02),
            headline: "마이크로소프트, 클라우드 인프라 투자 계획 재확인",
            imageURL: nil,
            aiJudgement: NewsroomAIJudgement(
                title: "AI는 이렇게 판단했어요",
                headline: "투자 확대는 수요 기대와 비용 부담을 함께 봐야 하는 신호예요.",
                reason: "인프라 투자 재확인은 클라우드·AI 수요가 견조하다는 신호로 읽히지만, 동시에 감가상각비 증가로 이어져 단기 영업이익률에는 부담으로 작용합니다. 두 요인이 상쇄되는 구간이라 뚜렷한 방향을 제시하기 어렵습니다.",
                alignment: .neutral,
                usedNewsURLs: [],
                disclaimer: "본 내용은 투자 판단의 근거가 아닙니다."
            ),
            summaryBody: "마이크로소프트가 클라우드와 AI 수요 대응을 위한 인프라 투자 계획을 재확인했어요.",
            findings: [],
            sources: [
                source(id: "msft-1", title: "Microsoft reiterates cloud infrastructure plans", publisher: "Bloomberg", hoursAgo: 5.2)
            ],
            asOfAt: asOfAt,
            aiNotice: "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요."
        )
    }

    /// 종목별 상세 Mock을 티커로 찾을 때 쓰는 표. 없는 티커는 quiet 종목이라 상세가 없다는 뜻.
    static func detail(for ticker: String) -> NewsroomTickerDetail? {
        switch ticker.uppercased() {
        case "NVDA": return nvidiaDetail
        case "AAPL": return appleDetail
        case "MSFT": return msftDetail
        default: return nil
        }
    }

    private static let nvidiaHeadline = "엔비디아, 데이터센터 매출 예상 상회 속 다음 분기 전망 제시"
    private static let nvidiaSubheadline = "실적은 예상을 웃돌았고 다음 분기 가이던스는 예상 범위 안이었어요."
    private static let appleHeadline = "애플, 인도 생산 비중 확대 계획 보도"
    private static let appleSubheadline = "공급망 다변화 움직임이 이어졌지만 회사의 공식 발표는 아직 없어요."
    private static let msftSubheadline = "AI 수요 대응을 위한 데이터센터 투자가 이어질 예정이에요."

    /// 서버는 quiet 종목의 headline/summary를 "{n}일째 특이사항 없음" / "계속 지켜보고 있어요"로
    /// 미리 채워 보낸다(NewsroomService.buildHoldingBriefing) — 클라이언트는 그대로 표시만 한다.
    private static func quietHolding(ticker: String, name: String, weight: Int, quietDays: Int) -> NewsroomHoldingBriefing {
        holding(
            ticker: ticker, name: name, weight: weight, type: .quiet,
            dailyChangePct: nil, totalImpactPct: nil,
            headline: "\(quietDays)일째 특이사항 없음", summary: "계속 지켜보고 있어요"
        )
    }

    private static func holding(
        ticker: String,
        name: String,
        weight: Int,
        type: NewsroomBriefingType,
        dailyChangePct: Double?,
        totalImpactPct: Double?,
        headline: String?,
        summary: String?
    ) -> NewsroomHoldingBriefing {
        NewsroomHoldingBriefing(
            ticker: ticker,
            name: name,
            weightPercent: Double(weight),
            briefingType: type,
            dailyChangePercent: dailyChangePct,
            totalAssetImpactPercent: totalImpactPct,
            headline: headline,
            summary: summary,
            detailPath: "/api/users/1/newsroom/\(ticker)"
        )
    }

    private static func source(id: String, title: String, publisher: String, hoursAgo: Double) -> NewsroomSourceItem {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return NewsroomSourceItem(
            newsId: id,
            title: title,
            publisher: publisher,
            publishedAtRaw: formatter.string(from: hoursBeforeGeneration(hoursAgo)),
            url: URL(string: "https://example.com/\(id)")
        )
    }
}
