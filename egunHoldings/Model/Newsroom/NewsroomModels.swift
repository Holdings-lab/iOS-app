import Foundation

enum NewsroomDigestMode: String, CaseIterable, Identifiable, Equatable {
    case oneMinute = "1분"
    case threeMinutes = "3분"
    case all = "전체"

    var id: String { rawValue }

    var storyLimit: Int? {
        switch self {
        case .oneMinute:
            return 4
        case .threeMinutes:
            return 6
        case .all:
            return nil
        }
    }

    var subtitle: String {
        switch self {
        case .oneMinute:
            return "핵심만 빠르게"
        case .threeMinutes:
            return "조금 더 넓게"
        case .all:
            return "전체 브리핑"
        }
    }
}

extension PolicyNewsItem {
    var newsroomRelationText: String {
        if !relatedTickers.isEmpty {
            return "\(relatedTickers.joined(separator: " · ")) 노출이 있어 먼저 볼 가치가 있어요."
        }

        return "내 자산 직접 관련도는 낮지만 오늘 시장 맥락을 이해하는 데 필요해요."
    }

    var newsroomCapsuleText: String {
        summary
    }
}
