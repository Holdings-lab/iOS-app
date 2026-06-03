import Foundation
import SwiftUI

nonisolated struct TodayDashboardResponseDTO: Decodable {
    let homeHeader: TodayHomeHeaderDTO?
    let featuredCard: TodayFeaturedSignalCardDTO?
    let portfolioCard: TodayHomePortfolioCardDTO?
    let secondarySignals: [TodaySecondarySignalItemDTO]?
    let quickInterpretation: TodayQuickInterpretationDTO?
    let detailTabs: TodayDetailTabsDTO?
    let checkpointTab: TodayCheckpointTabDTO?
    let briefingHeadline: String?
    let briefingParagraphs: [String]?
    let disclaimer: String?
    let updatedAt: String?
    let dataStatus: TodayDataStatusDTO?
    let portfolioSnapshot: PortfolioSnapshotDTO?
    let judgment: TodayJudgmentDTO?
    let portfolio: TodayPortfolioSummaryDTO?
    let policyEvents: [TodayPolicyEventDTO]?
    let holdings: [TodayHoldingDTO]?
    let noActionReasons: [String]?
    let noActionWatchCondition: String?
    let primaryCheckpointText: String?
    let checkpoints: [TodayCheckpointDTO]?

    func toDomain(
        fallback: TodayDashboard,
        userId: Int64?,
        eventResponse: TodayEventsResponseDTO? = nil
    ) -> TodayDashboard {
        let nextSnapshot = portfolioSnapshot?.toDomain(fallback: fallback.portfolioSnapshot)
            ?? fallback.portfolioSnapshot

        let nextPolicyEvents = policyEvents?.enumerated().map { index, dto in
            dto.toDomain(fallback: fallback.policyEvents[safe: index])
        }.nonEmpty ?? fallback.policyEvents

        let nextHoldings = holdings?.enumerated().map { index, dto in
            dto.toDomain(fallback: fallback.holdings[safe: index])
        }.nonEmpty ?? fallback.holdings

        let nextPortfolio = portfolio?.toDomain(fallback: fallback.portfolio)
            ?? portfolioCard?.toDomain(fallback: fallback.portfolio)
            ?? TodayDashboardBuilder.makePortfolioSummary(
                from: nextSnapshot,
                userAssetProfile: fallback.userAssetProfile,
                fallback: fallback.portfolio
            )

        let nextJudgment = judgment?.toDomain(fallback: fallback.judgment)
            ?? makeJudgment(fallback: fallback.judgment)
            ?? fallback.judgment
        let nextThemeSignals = makeThemeSignals(fallback: fallback.themeSignals)
        let nextPolicyReadings = eventResponse?.toPolicyReadings(fallback: fallback.policyReadings)
            ?? fallback.policyReadings
        let homeBriefingConnected = featuredCard != nil
            || secondarySignals?.isEmpty == false
            || quickInterpretation != nil
            || detailTabs != nil
        let eventsConnected = eventResponse?.items?.isEmpty == false

        return TodayDashboard(
            userAssetProfile: fallback.userAssetProfile,
            portfolioSnapshot: nextSnapshot,
            judgment: nextJudgment,
            portfolio: nextPortfolio,
            policyEvents: nextPolicyEvents,
            holdings: nextHoldings,
            noActionReasons: noActionReasons?.nonEmpty ?? fallback.noActionReasons,
            noActionWatchCondition: noActionWatchCondition ?? fallback.noActionWatchCondition,
            primaryCheckpointText: primaryCheckpointText
                ?? checkpoints?.first?.text
                ?? checkpointTab?.primaryCheckpointText
                ?? fallback.primaryCheckpointText,
            dataUpdatedAt: dataStatus?.updatedAt
                ?? updatedAt
                ?? checkpointTab?.reflectionStatus?.updatedAt
                ?? fallback.dataUpdatedAt,
            dataSources: dataStatus?.sources?.nonEmpty
                ?? checkpointTab?.reflectionStatus?.sources?.nonEmpty
                ?? fallback.dataSources,
            aiSummaryStatus: dataStatus?.aiSummaryStatus
                ?? checkpointTab?.reflectionStatus?.reviewStatus
                ?? fallback.aiSummaryStatus,
            themeSignals: nextThemeSignals,
            policyReadings: nextPolicyReadings,
            adjustmentProposal: fallback.adjustmentProposal,
            apiConnectionStatuses: Self.connectionStatuses(
                userId: userId,
                homeBriefingConnected: homeBriefingConnected,
                eventsConnected: eventsConnected
            )
        )
    }

    private func makeJudgment(fallback: TodayJudgment) -> TodayJudgment? {
        guard quickInterpretation != nil || detailTabs != nil || featuredCard != nil else {
            return nil
        }

        let summaryTab = detailTabs?.summaryTab
        let evidenceTab = detailTabs?.evidenceTab
        let quick = quickInterpretation
        let featured = featuredCard
        let impactPath = evidenceTab?.impactPaths?
            .map { [$0.title, $0.description].compactMap { $0 }.joined(separator: ": ") }
            .filter { !$0.isEmpty }
            .joined(separator: " -> ")

        return TodayJudgment(
            title: featured?.recommendedAction
                ?? summaryTab?.oneLineSummary
                ?? quick?.judgementBadge?.text
                ?? fallback.title,
            type: TodayDTOMapper.judgmentType(
                from: featured?.judgement ?? summaryTab?.judgement ?? quick?.judgementBadge?.displayType,
                fallback: fallback.type
            ),
            myExposure: featured?.myAssetExposurePercent ?? summaryTab?.exposurePercent ?? fallback.myExposure,
            validUntil: quick?.revisitTime ?? fallback.validUntil,
            invalidationCondition: quick?.weakenCondition
                ?? evidenceTab?.invalidationConditions?.first
                ?? fallback.invalidationCondition,
            forEvidence: evidenceTab?.coreEvidences?.nonEmpty
                ?? [quick?.coreReason, quick?.myAssetImpact, summaryTab?.oneLineSummary].compactMap { $0 }.nonEmpty
                ?? fallback.forEvidence,
            againstEvidence: evidenceTab?.counterEvidences?.nonEmpty ?? fallback.againstEvidence,
            deliveryPath: impactPath?.nonEmptyString ?? fallback.deliveryPath
        )
    }

    private func makeThemeSignals(fallback: [PortfolioThemeSignal]) -> [PortfolioThemeSignal] {
        var signals: [PortfolioThemeSignal] = []

        if let featuredCard {
            let fallbackTheme = fallback.first?.theme ?? .bigTech
            signals.append(
                featuredCard.toThemeSignal(
                    fallbackTheme: fallbackTheme,
                    narrative: briefingParagraphs?.joined(separator: "\n")
                )
            )
        }

        for (index, signal) in (secondarySignals ?? []).enumerated() {
            signals.append(
                signal.toThemeSignal(
                    fallbackTheme: fallback[safe: min(index + 1, max(fallback.count - 1, 0))]?.theme ?? .semiconductor
                )
            )
        }

        var seenThemes: Set<String> = []
        let deduped = signals.filter { signal in
            let key = signal.theme.rawValue
            guard !seenThemes.contains(key) else { return false }
            seenThemes.insert(key)
            return true
        }

        if deduped.isEmpty {
            return fallback
        }

        let fallbackRemainder = fallback.filter { signal in
            !seenThemes.contains(signal.theme.rawValue)
        }

        return Array((deduped + fallbackRemainder).prefix(4))
    }

    private static func connectionStatuses(
        userId: Int64?,
        homeBriefingConnected: Bool,
        eventsConnected: Bool
    ) -> [TodayAPIConnectionStatus] {
        let userScoped = userId.map(String.init) ?? "{userId}"

        return [
            TodayAPIConnectionStatus(
                id: "theme-signals",
                title: "내 포트폴리오 영향 Top 3",
                endpoint: "GET /api/users/\(userScoped)/home/briefing",
                detail: homeBriefingConnected ? "featuredCard/secondarySignals 매핑" : "응답 필드 없음, Mock 유지",
                kind: homeBriefingConnected ? .connected : .fallback
            ),
            TodayAPIConnectionStatus(
                id: "policy-readings",
                title: "오늘 읽을 정책 이벤트",
                endpoint: "GET /api/users/\(userScoped)/events",
                detail: eventsConnected ? "events.items 매핑" : "응답 필드 없음, Mock 유지",
                kind: eventsConnected ? .connected : .fallback
            ),
            TodayAPIConnectionStatus(
                id: "adjustment-proposal",
                title: "대응 대기 중",
                endpoint: "백엔드 모델 필요",
                detail: "리밸런싱 제안 모델이 Today 브리핑에 아직 없음",
                kind: .pending
            )
        ]
    }
}

nonisolated struct TodayDataStatusDTO: Decodable {
    let updatedAt: String?
    let sources: [String]?
    let aiSummaryStatus: String?
}

nonisolated struct TodayHomeHeaderDTO: Decodable {
    let greeting: String?
    let userName: String?
    let profileInitial: String?
}

nonisolated struct TodayFeaturedSignalCardDTO: Decodable {
    let signalTitle: String?
    let myAssetExposurePercent: Int?
    let recommendedAction: String?
    let judgement: String?
    let upsideProbability: Int?
    let downsideProbability: Int?
    let volatility: Int?
    let confidence: Int?
    let coreReason: String?

    func toThemeSignal(
        fallbackTheme: PortfolioThemeSignal.Theme,
        narrative: String?
    ) -> PortfolioThemeSignal {
        let theme = TodayDTOMapper.theme(from: signalTitle) ?? fallbackTheme
        let exposure = myAssetExposurePercent ?? 0

        return PortfolioThemeSignal(
            id: UUID(),
            theme: theme,
            myExposurePercent: exposure,
            verdictKind: TodayDTOMapper.verdictKind(from: judgement ?? recommendedAction),
            prescription: TodayDecisionPrescription(
                summary: coreReason ?? signalTitle ?? "서버 브리핑을 기준으로 정책 영향을 점검합니다.",
                action: recommendedAction ?? judgement ?? "정책 영향을 확인하세요",
                nowPercent: "\(exposure)%",
                goalLabel: nil,
                narrative: narrative
            ),
            nextEventLabel: nil,
            relatedEventId: nil
        )
    }
}

nonisolated struct TodayHomePortfolioCardDTO: Decodable {
    let totalAsset: String?
    let returnRate: String?
    let currentRiskLabel: String?
    let currentRiskSummary: String?
    let themeExposureBars: [TodayThemeExposureBarDTO]?

    func toDomain(fallback: TodayPortfolioSummary) -> TodayPortfolioSummary {
        TodayPortfolioSummary(
            totalAsset: TodayDTOMapper.parseCurrency(totalAsset) ?? fallback.totalAsset,
            todayChange: TodayDTOMapper.parsePercent(returnRate) ?? fallback.todayChange,
            todayChangeAmt: fallback.todayChangeAmt,
            cashDefense: fallback.cashDefense,
            dollarDefense: fallback.dollarDefense,
            overtradeRisk: currentRiskSummary ?? fallback.overtradeRisk,
            topExposures: themeExposureBars?.enumerated().map { index, dto in
                dto.toDomain(fallback: fallback.topExposures[safe: index])
            }.nonEmpty ?? fallback.topExposures,
            riskLevel: currentRiskLabel ?? fallback.riskLevel,
            weeklySparklinePoints: fallback.weeklySparklinePoints
        )
    }
}

nonisolated struct TodayThemeExposureBarDTO: Decodable {
    let theme: String?
    let exposurePercent: Int?

    func toDomain(fallback: TodayExposureItem?) -> TodayExposureItem {
        let fallback = fallback ?? TodayExposureItem(theme: theme ?? "정책", pct: 0, color: PSColor.electricBlue)

        return TodayExposureItem(
            theme: theme ?? fallback.theme,
            pct: exposurePercent ?? fallback.pct,
            color: TodayDTOMapper.color(hex: nil, token: theme, fallback: fallback.color)
        )
    }
}

nonisolated struct TodaySecondarySignalItemDTO: Decodable {
    let title: String?
    let shortJudgement: String?
    let exposurePercent: Int?
    let oneLineReason: String?

    func toThemeSignal(fallbackTheme: PortfolioThemeSignal.Theme) -> PortfolioThemeSignal {
        let theme = TodayDTOMapper.theme(from: title) ?? fallbackTheme
        let exposure = exposurePercent ?? 0

        return PortfolioThemeSignal(
            id: UUID(),
            theme: theme,
            myExposurePercent: exposure,
            verdictKind: TodayDTOMapper.verdictKind(from: shortJudgement),
            prescription: TodayDecisionPrescription(
                summary: oneLineReason ?? title ?? "서버 보조 신호를 기준으로 점검합니다.",
                action: shortJudgement ?? "흐름을 확인하세요",
                nowPercent: "\(exposure)%",
                goalLabel: nil,
                narrative: nil
            ),
            nextEventLabel: nil,
            relatedEventId: nil
        )
    }
}

nonisolated struct TodayQuickInterpretationDTO: Decodable {
    let judgementBadge: TodayJudgementBadgeDTO?
    let myAssetImpact: String?
    let coreReason: String?
    let keyNumbers: [TodayKeyNumberItemDTO]?
    let revisitTime: String?
    let weakenCondition: String?
    let tip: String?
}

nonisolated struct TodayJudgementBadgeDTO: Decodable {
    let text: String?
    let color: String?
    let displayType: String?
}

nonisolated struct TodayKeyNumberItemDTO: Decodable {
    let label: String?
    let baseline: String?
    let description: String?
}

nonisolated struct TodayDetailTabsDTO: Decodable {
    let summaryTab: TodaySummaryTabDTO?
    let evidenceTab: TodayEvidenceTabDTO?
}

nonisolated struct TodaySummaryTabDTO: Decodable {
    let judgement: String?
    let exposurePercent: Int?
    let oneLineSummary: String?
}

nonisolated struct TodayEvidenceTabDTO: Decodable {
    let impactPaths: [TodayImpactPathItemDTO]?
    let coreEvidences: [String]?
    let counterEvidences: [String]?
    let invalidationConditions: [String]?
}

nonisolated struct TodayImpactPathItemDTO: Decodable {
    let icon: String?
    let title: String?
    let description: String?
}

nonisolated struct TodayCheckpointTabDTO: Decodable {
    let policyCheckpoints: [TodayBriefingCheckpointDTO]?
    let marketCheckpoints: [TodayBriefingCheckpointDTO]?
    let revisitAlert: String?
    let reflectionStatus: TodayReflectionStatusDTO?

    var primaryCheckpointText: String? {
        policyCheckpoints?.first?.displayText
            ?? marketCheckpoints?.first?.displayText
            ?? revisitAlert
    }
}

nonisolated struct TodayBriefingCheckpointDTO: Decodable {
    let title: String?
    let threshold: String?
    let reason: String?

    var displayText: String {
        [title, threshold, reason]
            .compactMap { $0?.nonEmptyString }
            .joined(separator: " · ")
    }
}

nonisolated struct TodayReflectionStatusDTO: Decodable {
    let updatedAt: String?
    let sources: [String]?
    let reviewStatus: String?
}

nonisolated struct PortfolioSnapshotDTO: Decodable {
    let amountText: String?
    let changePercentText: String?
    let insightText: String?

    func toDomain(fallback: PortfolioSnapshot) -> PortfolioSnapshot {
        PortfolioSnapshot(
            amountText: amountText ?? fallback.amountText,
            changePercentText: changePercentText ?? fallback.changePercentText,
            insightText: insightText ?? fallback.insightText
        )
    }
}

nonisolated struct TodayJudgmentDTO: Decodable {
    let title: String?
    let type: String?
    let myExposure: Int?
    let validUntil: String?
    let invalidationCondition: String?
    let forEvidence: [String]?
    let againstEvidence: [String]?
    let deliveryPath: String?

    func toDomain(fallback: TodayJudgment) -> TodayJudgment {
        TodayJudgment(
            title: title ?? fallback.title,
            type: TodayDTOMapper.judgmentType(from: type, fallback: fallback.type),
            myExposure: myExposure ?? fallback.myExposure,
            validUntil: validUntil ?? fallback.validUntil,
            invalidationCondition: invalidationCondition ?? fallback.invalidationCondition,
            forEvidence: forEvidence?.nonEmpty ?? fallback.forEvidence,
            againstEvidence: againstEvidence?.nonEmpty ?? fallback.againstEvidence,
            deliveryPath: deliveryPath ?? fallback.deliveryPath
        )
    }
}

nonisolated struct TodayPortfolioSummaryDTO: Decodable {
    let totalAsset: Int?
    let todayChange: Double?
    let todayChangeAmt: Int?
    let cashDefense: Int?
    let dollarDefense: Int?
    let overtradeRisk: String?
    let topExposures: [TodayExposureItemDTO]?
    let riskLevel: String?

    func toDomain(fallback: TodayPortfolioSummary) -> TodayPortfolioSummary {
        TodayPortfolioSummary(
            totalAsset: totalAsset ?? fallback.totalAsset,
            todayChange: todayChange ?? fallback.todayChange,
            todayChangeAmt: todayChangeAmt ?? fallback.todayChangeAmt,
            cashDefense: cashDefense ?? fallback.cashDefense,
            dollarDefense: dollarDefense ?? fallback.dollarDefense,
            overtradeRisk: overtradeRisk ?? fallback.overtradeRisk,
            topExposures: topExposures?.enumerated().map { index, dto in
                dto.toDomain(fallback: fallback.topExposures[safe: index])
            }.nonEmpty ?? fallback.topExposures,
            riskLevel: riskLevel ?? fallback.riskLevel
        )
    }
}

nonisolated struct TodayExposureItemDTO: Decodable {
    let theme: String?
    let pct: Int?
    let colorHex: String?
    let colorToken: String?

    func toDomain(fallback: TodayExposureItem?) -> TodayExposureItem {
        let fallback = fallback ?? TodayExposureItem(theme: "정책", pct: 0, color: PSColor.electricBlue)

        return TodayExposureItem(
            theme: theme ?? fallback.theme,
            pct: pct ?? fallback.pct,
            color: TodayDTOMapper.color(hex: colorHex, token: colorToken, fallback: fallback.color)
        )
    }
}

nonisolated struct TodayPolicyEventDTO: Decodable {
    let id: Int?
    let title: String?
    let institution: String?
    let dDay: String?
    let date: String?
    let status: String?
    let colorHex: String?
    let colorToken: String?
    let myExposure: Int?
    let relatedAssets: [String]?
    let summary: String?
    let direction: String?
    let evidence: [String]?
    let counterEvidence: String?
    let invalidationConditions: [String]?
    let sources: [String]?
    let verified: Bool?
    let updatedAt: String?
    let impactFlow: [String]?
    let timelag: String?
    let confidence: Int?

    func toDomain(fallback: TodayPolicyEvent?) -> TodayPolicyEvent {
        let fallback = fallback ?? TodayMockData.policyEvents.first!

        return TodayPolicyEvent(
            id: id ?? fallback.id,
            title: title ?? fallback.title,
            institution: institution ?? fallback.institution,
            dDay: dDay ?? fallback.dDay,
            date: date ?? fallback.date,
            status: TodayDTOMapper.policyStatus(from: status, fallback: fallback.status),
            color: TodayDTOMapper.color(hex: colorHex, token: colorToken, fallback: fallback.color),
            myExposure: myExposure ?? fallback.myExposure,
            relatedAssets: relatedAssets?.nonEmpty ?? fallback.relatedAssets,
            summary: summary ?? fallback.summary,
            direction: TodayDTOMapper.trendDirection(from: direction, fallback: fallback.direction),
            evidence: evidence?.nonEmpty ?? fallback.evidence,
            counterEvidence: counterEvidence ?? fallback.counterEvidence,
            invalidationConditions: invalidationConditions?.nonEmpty ?? fallback.invalidationConditions,
            sources: sources?.nonEmpty ?? fallback.sources,
            verified: verified ?? fallback.verified,
            updatedAt: updatedAt ?? fallback.updatedAt,
            impactFlow: ImpactFlow(steps: impactFlow?.nonEmpty ?? fallback.impactFlow.steps),
            timelag: timelag ?? fallback.timelag,
            confidence: confidence ?? fallback.confidence
        )
    }
}

nonisolated struct TodayHoldingDTO: Decodable {
    let id: String?
    let name: String?
    let ticker: String?
    let category: String?
    let weight: Int?
    let value: Int?
    let change: Double?
    let exposedThemes: [TodayThemeExposureDTO]?
    let colorHex: String?
    let colorToken: String?

    func toDomain(fallback: TodayHolding?) -> TodayHolding {
        let fallback = fallback ?? TodayMockData.holdings.first!

        return TodayHolding(
            id: id ?? fallback.id,
            name: name ?? fallback.name,
            ticker: ticker ?? fallback.ticker,
            category: category ?? fallback.category,
            weight: weight ?? fallback.weight,
            value: value ?? fallback.value,
            change: change ?? fallback.change,
            exposedThemes: exposedThemes?.enumerated().map { index, dto in
                dto.toDomain(fallback: fallback.exposedThemes[safe: index])
            }.nonEmpty ?? fallback.exposedThemes,
            color: TodayDTOMapper.color(hex: colorHex, token: colorToken, fallback: fallback.color)
        )
    }
}

nonisolated struct TodayThemeExposureDTO: Decodable {
    let theme: String?
    let intensity: String?
    let colorHex: String?
    let colorToken: String?

    func toDomain(fallback: TodayThemeExposure?) -> TodayThemeExposure {
        let fallback = fallback ?? TodayThemeExposure(theme: "정책", intensity: .medium, color: PSColor.electricBlue)

        return TodayThemeExposure(
            theme: theme ?? fallback.theme,
            intensity: TodayDTOMapper.importance(from: intensity, fallback: fallback.intensity),
            color: TodayDTOMapper.color(hex: colorHex, token: colorToken, fallback: fallback.color)
        )
    }
}

nonisolated struct TodayCheckpointDTO: Decodable {
    let text: String?
}

nonisolated struct TodayEventsResponseDTO: Decodable {
    let dateSegments: [String]?
    let categories: [String]?
    let items: [TodayEventItemDTO]?

    func toPolicyReadings(fallback: [PolSignalPolicyReading]) -> [PolSignalPolicyReading] {
        let mapped = (items ?? []).enumerated().map { index, item in
            item.toPolicyReading(index: index)
        }

        return mapped.nonEmpty ?? fallback
    }
}

nonisolated struct TodayEventItemDTO: Decodable {
    let eventId: Int?
    let timeText: String?
    let title: String?
    let statusText: String?
    let tags: [String]?
    let importanceStars: Int?
    let countdownText: String?
    let relatedAssets: [String]?
    let alertEnabled: Bool?

    func toPolicyReading(index: Int) -> PolSignalPolicyReading {
        let keywords = (tags?.nonEmpty ?? relatedAssets?.nonEmpty ?? ["정책"])
            .prefix(3)
            .map { $0 }
        let keywordText = keywords.joined(separator: ", ")
        let sourceText = tags?.first ?? "뉴스"

        return PolSignalPolicyReading(
            id: eventId ?? index + 1,
            date: countdownText ?? timeText ?? "오늘",
            institution: sourceText,
            title: title ?? "관심 키워드 뉴스",
            keywords: Array(keywords),
            whatHappened: "서버 이벤트 목록에서 받은 뉴스예요. 관심 키워드 \(keywordText)이(가) 포함되어 있어 짧게 읽을 수 있도록 정리했어요.",
            aiSummary: [
                statusText ?? "새 뉴스가 도착했어요",
                "\(keywords.first ?? "관심 키워드")와 연결돼요",
                "원문 확인 전 빠른 요약이에요"
            ],
            keywordLinks: keywords.map { keyword in
                PolSignalPolicyKeywordLink(
                    kw: keyword,
                    why: "\(keyword) 키워드가 이 뉴스의 분류 태그에 포함돼요."
                )
            },
            followUps: [
                "이 키워드는 어떤 기사에서 자주 등장할까요?",
                "원문에서 확인할 표현은 무엇일까요?"
            ],
            readMinutes: max(1, min(5, importanceStars ?? 2))
        )
    }
}

nonisolated private enum TodayDTOMapper {
    static func judgmentType(from value: String?, fallback: JudgmentType) -> JudgmentType {
        switch normalized(value) {
        case "confirm", "check", "확인":
            return .confirm
        case "wait", "hold", "대기":
            return .wait
        case "defend", "defense", "방어":
            return .defend
        case "simulate", "simulation", "모의반영":
            return .simulate
        default:
            return fallback
        }
    }

    static func policyStatus(from value: String?, fallback: PSPolicyStatus) -> PSPolicyStatus {
        switch normalized(value) {
        case "scheduled", "예정":
            return .scheduled
        case "announced", "발표":
            return .announced
        case "changed", "변경":
            return .changed
        case "delayed", "지연":
            return .delayed
        default:
            return fallback
        }
    }

    static func trendDirection(from value: String?, fallback: TrendDirection) -> TrendDirection {
        switch normalized(value) {
        case "positive", "up", "bullish", "긍정":
            return .positive
        case "negative", "down", "bearish", "부정":
            return .negative
        case "mixed", "neutral", "혼조", "중립":
            return .mixed
        default:
            return fallback
        }
    }

    static func importance(from value: String?, fallback: PSImportance) -> PSImportance {
        switch normalized(value) {
        case "high", "높음":
            return .high
        case "medium", "중간":
            return .medium
        case "low", "낮음":
            return .low
        default:
            return fallback
        }
    }

    static func verdictKind(from value: String?) -> PolSignalVerdictKind? {
        let key = normalized(value)

        if key.contains("adjust")
            || key.contains("defend")
            || key.contains("대응")
            || key.contains("조정")
            || key.contains("줄이")
            || key.contains("방어") {
            return .adjust
        }

        if key.contains("review")
            || key.contains("confirm")
            || key.contains("check")
            || key.contains("점검")
            || key.contains("확인")
            || key.contains("주의") {
            return .review
        }

        if key.contains("watch")
            || key.contains("hold")
            || key.contains("wait")
            || key.contains("관망")
            || key.contains("유지")
            || key.contains("대기") {
            return .watch
        }

        return nil
    }

    static func theme(from value: String?) -> PortfolioThemeSignal.Theme? {
        let key = normalized(value)

        if key.contains("semi")
            || key.contains("chip")
            || key.contains("반도체")
            || key.contains("soxx") {
            return .semiconductor
        }

        if key.contains("finance")
            || key.contains("bank")
            || key.contains("rate")
            || key.contains("금융")
            || key.contains("금리")
            || key.contains("은행") {
            return .financials
        }

        if key.contains("green")
            || key.contains("energy")
            || key.contains("친환경")
            || key.contains("에너지")
            || key.contains("재생") {
            return .greenEnergy
        }

        if key.contains("tech")
            || key.contains("qqq")
            || key.contains("ai")
            || key.contains("빅테크") {
            return .bigTech
        }

        return nil
    }

    static func parseCurrency(_ text: String?) -> Int? {
        guard let text else { return nil }
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }

    static func parsePercent(_ text: String?) -> Double? {
        guard let text else { return nil }
        let normalized = text
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(normalized)
    }

    static func color(hex: String?, token: String?, fallback: Color) -> Color {
        if let hex, !hex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Color(hex: hex)
        }

        switch normalized(token) {
        case "blue", "electricblue", "금리":
            return PSColor.electricBlue
        case "purple", "반도체":
            return PSColor.purple
        case "emerald", "green":
            return PSColor.emerald
        case "yellow", "amber", "달러":
            return PSColor.yellow
        case "red":
            return PSColor.red
        case "cyan":
            return PSColor.cyan
        case "gray", "grey":
            return PSColor.gray
        default:
            return fallback
        }
    }

    private static func normalized(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .lowercased() ?? ""
    }
}

private extension Array {
    nonisolated subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    nonisolated var nonEmpty: Self? {
        isEmpty ? nil : self
    }
}

private extension String {
    nonisolated var nonEmptyString: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
