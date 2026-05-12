import Foundation
import SwiftUI

enum TodayRoute: Hashable {
    case notifications
    case settings
}

enum AppNotificationKind: String, CaseIterable, Hashable, Identifiable {
    case policy
    case news
    case volatility
    case asset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .policy:
            return "정책 업데이트"
        case .news:
            return "기사 업데이트"
        case .volatility:
            return "변동성 위험"
        case .asset:
            return "자산 변화"
        }
    }

    var iconName: String {
        switch self {
        case .policy:
            return "building.columns.fill"
        case .news:
            return "newspaper.fill"
        case .volatility:
            return "exclamationmark.triangle.fill"
        case .asset:
            return "chart.line.uptrend.xyaxis"
        }
    }

    var tintColor: Color {
        switch self {
        case .policy:
            return Color.brand
        case .news:
            return Color.brandLight
        case .volatility:
            return Color.up
        case .asset:
            return Color.warning
        }
    }
}

struct AppNotificationItem: Identifiable, Hashable {
    let id: String
    let kind: AppNotificationKind
    let title: String
    let message: String
    let occurredAt: Date
    let relatedTitle: String?
    var isRead: Bool

    init(
        id: String = UUID().uuidString,
        kind: AppNotificationKind,
        title: String,
        message: String,
        occurredAt: Date,
        relatedTitle: String? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.occurredAt = occurredAt
        self.relatedTitle = relatedTitle
        self.isRead = isRead
    }
}

struct AppNotificationDayGroup: Identifiable {
    let date: Date
    let items: [AppNotificationItem]

    var id: Date { date }
}
