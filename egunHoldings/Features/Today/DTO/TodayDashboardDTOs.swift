import Foundation
import SwiftUI

nonisolated struct TodayDashboardResponseDTO: Decodable {
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

    func toDomain(fallback: TodayDashboard) -> TodayDashboard {
        let nextSnapshot = portfolioSnapshot?.toDomain(fallback: fallback.portfolioSnapshot)
            ?? fallback.portfolioSnapshot

        let nextPolicyEvents = policyEvents?.enumerated().map { index, dto in
            dto.toDomain(fallback: fallback.policyEvents[safe: index])
        }.nonEmpty ?? fallback.policyEvents

        let nextHoldings = holdings?.enumerated().map { index, dto in
            dto.toDomain(fallback: fallback.holdings[safe: index])
        }.nonEmpty ?? fallback.holdings

        let nextPortfolio = portfolio?.toDomain(fallback: fallback.portfolio)
            ?? TodayDashboardBuilder.makePortfolioSummary(
                from: nextSnapshot,
                userAssetProfile: fallback.userAssetProfile,
                fallback: fallback.portfolio
            )

        let nextJudgment = judgment?.toDomain(fallback: fallback.judgment)
            ?? fallback.judgment

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
                ?? fallback.primaryCheckpointText,
            dataUpdatedAt: dataStatus?.updatedAt ?? updatedAt ?? fallback.dataUpdatedAt,
            dataSources: dataStatus?.sources?.nonEmpty ?? fallback.dataSources,
            aiSummaryStatus: dataStatus?.aiSummaryStatus ?? fallback.aiSummaryStatus
        )
    }
}

nonisolated struct TodayDataStatusDTO: Decodable {
    let updatedAt: String?
    let sources: [String]?
    let aiSummaryStatus: String?
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
