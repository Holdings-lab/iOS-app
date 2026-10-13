import Foundation

nonisolated struct OnboardingProfilePatchRequestDTO: Encodable {
    let investmentHorizon: String
    let riskTolerance: String
    let investmentStyle: String
    let interests: [String]
}
