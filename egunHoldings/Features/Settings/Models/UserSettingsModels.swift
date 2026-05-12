import Foundation

enum UserSettingsLoadState: Equatable {
    case idle
    case loading
    case loaded
    case usingFallback(message: String?)
}

enum SettingsVolatilityLevel: String, CaseIterable, Identifiable, Sendable {
    case medium = "MEDIUM"
    case high = "HIGH"
    case veryHigh = "VERY_HIGH"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .medium:
            return "보통 이상"
        case .high:
            return "높음 이상"
        case .veryHigh:
            return "매우 높음만"
        }
    }

    var summary: String {
        switch self {
        case .medium:
            return "평소보다 눈에 띄는 변동부터 알림"
        case .high:
            return "실제 대응 검토가 필요한 변동 위주"
        case .veryHigh:
            return "큰 손실 위험이 있는 경우만 알림"
        }
    }
}

enum SettingsNewsDigestMode: String, CaseIterable, Identifiable, Sendable {
    case immediate = "IMMEDIATE"
    case dailyDigest = "DAILY_DIGEST"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediate:
            return "즉시 알림"
        case .dailyDigest:
            return "하루 요약"
        }
    }
}

enum SettingsDataSyncMode: String, CaseIterable, Identifiable, Sendable {
    case automatic = "AUTOMATIC"
    case manual = "MANUAL"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "자동"
        case .manual:
            return "수동"
        }
    }
}

struct UserSettings: Equatable, Sendable {
    var account: UserAccountSettings
    var rebalancing: UserRebalancingSettings
    var notifications: UserNotificationSettings
    var portfolio: UserPortfolioSettings
    var data: UserDataSettings
    var guide: UserGuideSettings

    static func makeDefault(connectedBrokerText: String = "연결 전") -> UserSettings {
        UserSettings(
            account: UserAccountSettings(
                displayName: "투자자님",
                loginAccount: "소셜 로그인",
                authProvider: "Kakao",
                memberSince: "2026.05.12"
            ),
            rebalancing: UserRebalancingSettings(
                investmentProfile: .balanced,
                targetCashWeight: 10,
                rebalanceThreshold: 5,
                maxSingleAssetWeight: 25,
                minTradeAmount: 10_000
            ),
            notifications: UserNotificationSettings(),
            portfolio: UserPortfolioSettings(
                connectedBrokerText: connectedBrokerText,
                brokerPermissionText: "읽기 전용",
                lastSyncedAt: "방금 전",
                volatilityLevel: .high,
                policyImpactThreshold: 20
            ),
            data: UserDataSettings(
                syncMode: .automatic,
                syncIntervalText: "앱 실행 시 자동",
                sources: [
                    "한국은행",
                    "미 연준",
                    "블룸버그",
                    "로이터",
                    "연합뉴스"
                ]
            ),
            guide: UserGuideSettings(
                privacyItems: [
                    "증권사 연결 정보는 읽기 전용으로 사용합니다.",
                    "보유 자산은 정책 영향도 계산에만 사용합니다.",
                    "푸시 토큰은 알림 발송 목적으로만 저장됩니다."
                ],
                disclaimerItems: [
                    "이 앱은 투자 판단을 돕는 정보 제공 서비스입니다.",
                    "리밸런싱과 알림은 매수/매도 권유가 아닙니다.",
                    "최종 투자 결정과 책임은 사용자에게 있습니다."
                ]
            )
        )
    }
}

struct UserAccountSettings: Equatable, Sendable {
    var displayName: String
    var loginAccount: String
    var authProvider: String
    var memberSince: String
}

struct UserRebalancingSettings: Equatable, Sendable {
    var investmentProfile: InvestmentProfile
    var targetCashWeight: Int
    var rebalanceThreshold: Int
    var maxSingleAssetWeight: Int
    var minTradeAmount: Int
}

struct UserNotificationSettings: Equatable, Sendable {
    var policyPushEnabled = true
    var newsPushEnabled = true
    var volatilityPushEnabled = true
    var quietHoursEnabled = true
    var quietHoursStart = "오후 10:00"
    var quietHoursEnd = "오전 7:00"
    var policyCategories = ["금리", "산업", "세제"]
    var policyImpactThreshold = 20
    var newsDigestMode: SettingsNewsDigestMode = .immediate
    var highRelevanceNewsOnly = true
    var volatilityLevel: SettingsVolatilityLevel = .high
}

struct UserPortfolioSettings: Equatable, Sendable {
    var connectedBrokerText: String
    var brokerPermissionText: String
    var lastSyncedAt: String
    var volatilityLevel: SettingsVolatilityLevel
    var policyImpactThreshold: Int
}

struct UserDataSettings: Equatable, Sendable {
    var syncMode: SettingsDataSyncMode
    var syncIntervalText: String
    var sources: [String]
}

struct UserGuideSettings: Equatable, Sendable {
    var privacyItems: [String]
    var disclaimerItems: [String]
}
