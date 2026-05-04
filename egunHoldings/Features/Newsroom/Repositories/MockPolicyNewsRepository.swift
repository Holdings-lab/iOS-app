import Foundation

nonisolated struct MockPolicyNewsRepository: PolicyNewsRepositoryProtocol {
    func fetchNews() async throws -> [PolicyNewsItem] {
        HomeNewsMockData.items
    }

    func fetchInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) async throws -> PolicyNewsInsight {
        if let insight = HomeNewsMockData.insights[item.id] {
            return insight
        }

        let holdingsLine = userAssetProfile.holdings
            .sorted { $0.weightPercent > $1.weightPercent }
            .prefix(3)
            .map { "\($0.name) \($0.weightPercent)%" }
            .joined(separator: ", ")

        return PolicyNewsInsight(
            articleID: item.id,
            headline: "기사 핵심을 내 자산 기준으로 다시 읽어볼 수 있도록 만든 기본 브리핑입니다.",
            generatedAt: Date(),
            sourceName: item.sourceName,
            sourceURL: item.sourceURL,
            articleSummary: [
                item.summary,
                "원문 전체 분석은 아직 준비되지 않아 기본 요약만 표시하고 있어요."
            ],
            portfolioHeadline: "현재 주요 보유 자산은 \(holdingsLine) 기준으로 연결해서 보면 좋아요.",
            portfolioBullets: [
                "기사와 직접 연결되는 자산 비중이 높을수록 당일 변동성을 더 크게 체감할 수 있어요.",
                "단일 기사만 보고 포지션을 크게 바꾸기보다 후속 발표를 같이 보는 편이 안전해요."
            ],
            actionChecklist: [
                "원문 출처와 발표 시점을 다시 확인하기",
                "기사와 연관된 ETF 또는 자산의 최근 변동 폭 점검하기"
            ],
            riskNotes: [
                "기본 브리핑은 실제 LLM 응답이 아니라 fallback 데이터예요."
            ],
            disclaimer: "이 시트는 기사 해설을 돕기 위한 참고 정보이며 투자 자문이 아니에요."
        )
    }
}
