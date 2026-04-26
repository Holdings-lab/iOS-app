import Foundation

struct SignupConsentDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let isRequired: Bool
    let detailBody: String
}
