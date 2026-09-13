import Foundation

nonisolated struct OnboardingProfilePatchRequestDTO: Encodable {
    let investmentHorizon: String
    let riskTolerance: String
    let investmentStyle: String
    let interests: [String]
}

nonisolated struct GoalUpdateRequestDTO: Encodable {
    let financialGoal: String
    let targetAmount: Int64
}
