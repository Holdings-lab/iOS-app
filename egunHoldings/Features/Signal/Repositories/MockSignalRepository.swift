import Foundation

nonisolated struct MockSignalRepository: SignalRepositoryProtocol {
    func fetchThemeSignals() async throws -> [PortfolioThemeSignal] {
        PolSignalFlowMockData.todayThemeSignals
    }

    func fetchSignalCards(theme: PortfolioThemeSignal.Theme) async throws -> [SignalCard] {
        // Phase 1.5 mock - 테마별 예시 카드.
        switch theme {
        case .bigTech:
            return [
                SignalCard(
                    id: UUID(),
                    intensity: .veryHigh,
                    title: "금리 결정이 빅테크 방향을 가를 수 있어요",
                    description: "이번 주 FOMC 금리 발표가 예정돼 있어요.",
                    newsTitle: "Fed, 금리 결정 앞두고 불확실성 고조"
                ),
                SignalCard(
                    id: UUID(),
                    intensity: .high,
                    title: "부정적 뉴스가 평소보다 빠르게 쌓이고 있어요",
                    description: "최근 5일간 빅테크 관련 부정 뉴스가 평소의 2배예요.",
                    newsTitle: "관세 리스크에 애플·엔비디아 동반 하락"
                ),
                SignalCard(
                    id: UUID(),
                    intensity: .medium,
                    title: "시장은 버티는데 뉴스는 흔들리고 있어요",
                    description: "가격 흐름과 뉴스 분위기가 반대 방향이에요. 방향이 정해지면 빠르게 움직일 수 있어요.",
                    newsTitle: nil
                )
            ]
        case .semiconductor:
            return [
                SignalCard(
                    id: UUID(),
                    intensity: .veryHigh,
                    title: "보조금 발표 결과에 따라 반도체가 크게 움직일 수 있어요",
                    description: "CHIPS 2차 배분 발표가 이번 주 예정돼 있어요.",
                    newsTitle: "미 상무부, 반도체 보조금 2차 배분 임박"
                )
            ]
        case .financials, .greenEnergy:
            return []
        }
    }

    func fetchEvents() async throws -> [PolSignalEvent] {
        PolSignalFlowMockData.events
    }

    func fetchEvent(id: Int) async throws -> PolSignalEvent {
        PolSignalFlowMockData.event(id: id)
    }
}
