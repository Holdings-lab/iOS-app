import Foundation

nonisolated struct WatchAssetsUpdateRequestDTO: Encodable {
    let sectors: [String]
}

nonisolated struct OnboardingSettingsPatchRequestDTO: Encodable {
    let investmentHorizon: String
    let maxDrawdownTolerance: Int
    let investmentProfile: String
}

nonisolated struct GoalUpdateRequestDTO: Encodable {
    let financialGoal: String
    let targetAmount: Int64
}
