import Foundation

struct SignalCard: Identifiable {
    let id: UUID
    let intensity: Intensity
    let title: String
    let description: String
    let newsTitle: String?

    enum Intensity {
        case veryHigh
        case high
        case medium
    }
}
