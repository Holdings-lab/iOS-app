import Foundation

// MARK: - Theme Signals (Today Top 3)

nonisolated struct SignalThemeResponseDTO: Decodable {
    let theme: String
    let myExposurePercent: Int
    let verdictKind: String?
    let prescription: SignalPrescriptionDTO?
    let nextEventLabel: String?
    let relatedEventId: Int?
}

nonisolated struct SignalPrescriptionDTO: Decodable {
    let summary: String
    let action: String
    let nowPercent: String?
    let goalLabel: String?
}

// MARK: - Signal Cards

nonisolated struct SignalCardResponseDTO: Decodable {
    let intensity: String
    let title: String
    let description: String
    let newsTitle: String?
}

// MARK: - Event Detail

nonisolated struct SignalEventResponseDTO: Decodable {
    let id: Int
    let category: String
    let institution: String
    let dDay: String
    let title: String
    let verdictKind: String
    let verdict: String
    let reason: String
    let expectedImpact: String
    let aiSummary: String
    let ctaTitle: String
    let weakeningCondition: String
    let sourceSummary: String
    let checkSchedule: String
}

// MARK: - Domain Mapping

extension SignalThemeResponseDTO {
    func toDomain(relatedEventId: Int? = nil) -> PortfolioThemeSignal? {
        let theme: PortfolioThemeSignal.Theme
        switch self.theme {
        case "big_tech":
            theme = .bigTech
        case "semiconductor":
            theme = .semiconductor
        case "financials":
            theme = .financials
        case "green_energy":
            theme = .greenEnergy
        default:
            return nil
        }

        let verdict: PolSignalVerdictKind? = verdictKind.flatMap {
            switch $0 {
            case "review":
                return .review
            case "watch":
                return .watch
            case "adjust":
                return .adjust
            default:
                return nil
            }
        }

        return PortfolioThemeSignal(
            id: UUID(),
            theme: theme,
            myExposurePercent: myExposurePercent,
            verdictKind: verdict,
            prescription: prescription.map {
                TodayDecisionPrescription(
                    summary: $0.summary,
                    action: $0.action,
                    nowPercent: $0.nowPercent,
                    goalLabel: $0.goalLabel,
                    narrative: nil
                )
            },
            nextEventLabel: nextEventLabel,
            relatedEventId: relatedEventId ?? self.relatedEventId
        )
    }
}

extension SignalCardResponseDTO {
    func toDomain() -> SignalCard? {
        let intensity: SignalCard.Intensity
        switch self.intensity {
        case "veryHigh":
            intensity = .veryHigh
        case "high":
            intensity = .high
        case "medium":
            intensity = .medium
        default:
            return nil
        }

        return SignalCard(
            id: UUID(),
            intensity: intensity,
            title: title,
            description: description,
            newsTitle: newsTitle
        )
    }
}
