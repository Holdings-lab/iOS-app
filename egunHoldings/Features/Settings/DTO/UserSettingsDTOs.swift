import Foundation

nonisolated struct UserSettingsResponseDTO: Decodable {
    let account: UserAccountSettingsDTO?
    let rebalancing: UserRebalancingSettingsDTO?
    let notifications: UserNotificationSettingsDTO?
    let portfolio: UserPortfolioSettingsDTO?
    let data: UserDataSettingsDTO?
    let guide: UserGuideSettingsDTO?

    let displayName: String?
    let loginAccount: String?
    let authProvider: String?
    let memberSince: String?
    let investmentProfile: String?
    let targetCashWeight: Int?
    let rebalanceThreshold: Int?
    let maxSingleAssetWeight: Int?
    let minTradeAmount: Int?
    let policyPushEnabled: Bool?
    let newsPushEnabled: Bool?
    let volatilityPushEnabled: Bool?
    let quietHoursEnabled: Bool?
    let quietHoursStart: String?
    let quietHoursEnd: String?
    let policyCategories: [String]?
    let policyImpactThreshold: Int?
    let newsDigestMode: String?
    let highRelevanceNewsOnly: Bool?
    let volatilityLevel: String?
    let connectedBrokerText: String?
    let brokerPermissionText: String?
    let lastSyncedAt: String?
    let syncMode: String?
    let syncIntervalText: String?
    let sources: [String]?
    let privacyItems: [String]?
    let disclaimerItems: [String]?

    func toDomain(fallback: UserSettings) -> UserSettings {
        UserSettings(
            account: account?.toDomain(fallback: fallback.account)
                ?? UserAccountSettings(
                    displayName: displayName ?? fallback.account.displayName,
                    loginAccount: loginAccount ?? fallback.account.loginAccount,
                    authProvider: authProvider ?? fallback.account.authProvider,
                    memberSince: memberSince ?? fallback.account.memberSince
                ),
            rebalancing: rebalancing?.toDomain(fallback: fallback.rebalancing)
                ?? UserRebalancingSettings(
                    investmentProfile: UserSettingsDTOMapper.investmentProfile(from: investmentProfile, fallback: fallback.rebalancing.investmentProfile),
                    targetCashWeight: targetCashWeight ?? fallback.rebalancing.targetCashWeight,
                    rebalanceThreshold: rebalanceThreshold ?? fallback.rebalancing.rebalanceThreshold,
                    maxSingleAssetWeight: maxSingleAssetWeight ?? fallback.rebalancing.maxSingleAssetWeight,
                    minTradeAmount: minTradeAmount ?? fallback.rebalancing.minTradeAmount
                ),
            notifications: notifications?.toDomain(fallback: fallback.notifications)
                ?? UserNotificationSettings(
                    policyPushEnabled: policyPushEnabled ?? fallback.notifications.policyPushEnabled,
                    newsPushEnabled: newsPushEnabled ?? fallback.notifications.newsPushEnabled,
                    volatilityPushEnabled: volatilityPushEnabled ?? fallback.notifications.volatilityPushEnabled,
                    quietHoursEnabled: quietHoursEnabled ?? fallback.notifications.quietHoursEnabled,
                    quietHoursStart: quietHoursStart ?? fallback.notifications.quietHoursStart,
                    quietHoursEnd: quietHoursEnd ?? fallback.notifications.quietHoursEnd,
                    policyCategories: policyCategories?.nonEmpty ?? fallback.notifications.policyCategories,
                    policyImpactThreshold: policyImpactThreshold ?? fallback.notifications.policyImpactThreshold,
                    newsDigestMode: UserSettingsDTOMapper.newsDigestMode(from: newsDigestMode, fallback: fallback.notifications.newsDigestMode),
                    highRelevanceNewsOnly: highRelevanceNewsOnly ?? fallback.notifications.highRelevanceNewsOnly,
                    volatilityLevel: UserSettingsDTOMapper.volatilityLevel(from: volatilityLevel, fallback: fallback.notifications.volatilityLevel)
                ),
            portfolio: portfolio?.toDomain(fallback: fallback.portfolio)
                ?? UserPortfolioSettings(
                    connectedBrokerText: connectedBrokerText ?? fallback.portfolio.connectedBrokerText,
                    brokerPermissionText: brokerPermissionText ?? fallback.portfolio.brokerPermissionText,
                    lastSyncedAt: lastSyncedAt ?? fallback.portfolio.lastSyncedAt,
                    volatilityLevel: UserSettingsDTOMapper.volatilityLevel(from: volatilityLevel, fallback: fallback.portfolio.volatilityLevel),
                    policyImpactThreshold: policyImpactThreshold ?? fallback.portfolio.policyImpactThreshold
                ),
            data: data?.toDomain(fallback: fallback.data)
                ?? UserDataSettings(
                    syncMode: UserSettingsDTOMapper.syncMode(from: syncMode, fallback: fallback.data.syncMode),
                    syncIntervalText: syncIntervalText ?? fallback.data.syncIntervalText,
                    sources: sources?.nonEmpty ?? fallback.data.sources
                ),
            guide: guide?.toDomain(fallback: fallback.guide)
                ?? UserGuideSettings(
                    privacyItems: privacyItems?.nonEmpty ?? fallback.guide.privacyItems,
                    disclaimerItems: disclaimerItems?.nonEmpty ?? fallback.guide.disclaimerItems
                )
        )
    }
}

nonisolated struct UserAccountSettingsDTO: Codable {
    let displayName: String?
    let loginAccount: String?
    let authProvider: String?
    let memberSince: String?

    func toDomain(fallback: UserAccountSettings) -> UserAccountSettings {
        UserAccountSettings(
            displayName: displayName ?? fallback.displayName,
            loginAccount: loginAccount ?? fallback.loginAccount,
            authProvider: authProvider ?? fallback.authProvider,
            memberSince: memberSince ?? fallback.memberSince
        )
    }
}

nonisolated struct UserRebalancingSettingsDTO: Codable {
    let investmentProfile: String?
    let targetCashWeight: Int?
    let rebalanceThreshold: Int?
    let maxSingleAssetWeight: Int?
    let minTradeAmount: Int?

    func toDomain(fallback: UserRebalancingSettings) -> UserRebalancingSettings {
        UserRebalancingSettings(
            investmentProfile: UserSettingsDTOMapper.investmentProfile(from: investmentProfile, fallback: fallback.investmentProfile),
            targetCashWeight: targetCashWeight ?? fallback.targetCashWeight,
            rebalanceThreshold: rebalanceThreshold ?? fallback.rebalanceThreshold,
            maxSingleAssetWeight: maxSingleAssetWeight ?? fallback.maxSingleAssetWeight,
            minTradeAmount: minTradeAmount ?? fallback.minTradeAmount
        )
    }
}

nonisolated struct UserNotificationSettingsDTO: Codable {
    let policyPushEnabled: Bool?
    let newsPushEnabled: Bool?
    let volatilityPushEnabled: Bool?
    let quietHoursEnabled: Bool?
    let quietHoursStart: String?
    let quietHoursEnd: String?
    let policyCategories: [String]?
    let policyImpactThreshold: Int?
    let newsDigestMode: String?
    let highRelevanceNewsOnly: Bool?
    let volatilityLevel: String?

    func toDomain(fallback: UserNotificationSettings) -> UserNotificationSettings {
        UserNotificationSettings(
            policyPushEnabled: policyPushEnabled ?? fallback.policyPushEnabled,
            newsPushEnabled: newsPushEnabled ?? fallback.newsPushEnabled,
            volatilityPushEnabled: volatilityPushEnabled ?? fallback.volatilityPushEnabled,
            quietHoursEnabled: quietHoursEnabled ?? fallback.quietHoursEnabled,
            quietHoursStart: quietHoursStart ?? fallback.quietHoursStart,
            quietHoursEnd: quietHoursEnd ?? fallback.quietHoursEnd,
            policyCategories: policyCategories?.nonEmpty ?? fallback.policyCategories,
            policyImpactThreshold: policyImpactThreshold ?? fallback.policyImpactThreshold,
            newsDigestMode: UserSettingsDTOMapper.newsDigestMode(from: newsDigestMode, fallback: fallback.newsDigestMode),
            highRelevanceNewsOnly: highRelevanceNewsOnly ?? fallback.highRelevanceNewsOnly,
            volatilityLevel: UserSettingsDTOMapper.volatilityLevel(from: volatilityLevel, fallback: fallback.volatilityLevel)
        )
    }
}

nonisolated struct UserPortfolioSettingsDTO: Codable {
    let connectedBrokerText: String?
    let brokerPermissionText: String?
    let lastSyncedAt: String?
    let volatilityLevel: String?
    let policyImpactThreshold: Int?

    func toDomain(fallback: UserPortfolioSettings) -> UserPortfolioSettings {
        UserPortfolioSettings(
            connectedBrokerText: connectedBrokerText ?? fallback.connectedBrokerText,
            brokerPermissionText: brokerPermissionText ?? fallback.brokerPermissionText,
            lastSyncedAt: lastSyncedAt ?? fallback.lastSyncedAt,
            volatilityLevel: UserSettingsDTOMapper.volatilityLevel(from: volatilityLevel, fallback: fallback.volatilityLevel),
            policyImpactThreshold: policyImpactThreshold ?? fallback.policyImpactThreshold
        )
    }
}

nonisolated struct UserDataSettingsDTO: Codable {
    let syncMode: String?
    let syncIntervalText: String?
    let sources: [String]?

    func toDomain(fallback: UserDataSettings) -> UserDataSettings {
        UserDataSettings(
            syncMode: UserSettingsDTOMapper.syncMode(from: syncMode, fallback: fallback.syncMode),
            syncIntervalText: syncIntervalText ?? fallback.syncIntervalText,
            sources: sources?.nonEmpty ?? fallback.sources
        )
    }
}

nonisolated struct UserGuideSettingsDTO: Codable {
    let privacyItems: [String]?
    let disclaimerItems: [String]?

    func toDomain(fallback: UserGuideSettings) -> UserGuideSettings {
        UserGuideSettings(
            privacyItems: privacyItems?.nonEmpty ?? fallback.privacyItems,
            disclaimerItems: disclaimerItems?.nonEmpty ?? fallback.disclaimerItems
        )
    }
}

nonisolated struct UserSettingsUpdateRequestDTO: Encodable {
    let account: UserAccountSettingsDTO
    let rebalancing: UserRebalancingSettingsDTO
    let notifications: UserNotificationSettingsDTO
    let portfolio: UserPortfolioSettingsDTO
    let data: UserDataSettingsDTO

    init(settings: UserSettings) {
        account = UserAccountSettingsDTO(
            displayName: settings.account.displayName,
            loginAccount: settings.account.loginAccount,
            authProvider: settings.account.authProvider,
            memberSince: settings.account.memberSince
        )
        rebalancing = UserRebalancingSettingsDTO(
            investmentProfile: settings.rebalancing.investmentProfile.rawValue,
            targetCashWeight: settings.rebalancing.targetCashWeight,
            rebalanceThreshold: settings.rebalancing.rebalanceThreshold,
            maxSingleAssetWeight: settings.rebalancing.maxSingleAssetWeight,
            minTradeAmount: settings.rebalancing.minTradeAmount
        )
        notifications = UserNotificationSettingsDTO(
            policyPushEnabled: settings.notifications.policyPushEnabled,
            newsPushEnabled: settings.notifications.newsPushEnabled,
            volatilityPushEnabled: settings.notifications.volatilityPushEnabled,
            quietHoursEnabled: settings.notifications.quietHoursEnabled,
            quietHoursStart: settings.notifications.quietHoursStart,
            quietHoursEnd: settings.notifications.quietHoursEnd,
            policyCategories: settings.notifications.policyCategories,
            policyImpactThreshold: settings.notifications.policyImpactThreshold,
            newsDigestMode: settings.notifications.newsDigestMode.rawValue,
            highRelevanceNewsOnly: settings.notifications.highRelevanceNewsOnly,
            volatilityLevel: settings.notifications.volatilityLevel.rawValue
        )
        portfolio = UserPortfolioSettingsDTO(
            connectedBrokerText: settings.portfolio.connectedBrokerText,
            brokerPermissionText: settings.portfolio.brokerPermissionText,
            lastSyncedAt: settings.portfolio.lastSyncedAt,
            volatilityLevel: settings.portfolio.volatilityLevel.rawValue,
            policyImpactThreshold: settings.portfolio.policyImpactThreshold
        )
        data = UserDataSettingsDTO(
            syncMode: settings.data.syncMode.rawValue,
            syncIntervalText: settings.data.syncIntervalText,
            sources: settings.data.sources
        )
    }
}

nonisolated private enum UserSettingsDTOMapper {
    static func investmentProfile(from value: String?, fallback: InvestmentProfile) -> InvestmentProfile {
        guard let value else { return fallback }
        return InvestmentProfile(rawValue: value) ?? fallback
    }

    static func volatilityLevel(from value: String?, fallback: SettingsVolatilityLevel) -> SettingsVolatilityLevel {
        guard let value else { return fallback }
        return SettingsVolatilityLevel(rawValue: value) ?? fallback
    }

    static func newsDigestMode(from value: String?, fallback: SettingsNewsDigestMode) -> SettingsNewsDigestMode {
        guard let value else { return fallback }
        return SettingsNewsDigestMode(rawValue: value) ?? fallback
    }

    static func syncMode(from value: String?, fallback: SettingsDataSyncMode) -> SettingsDataSyncMode {
        guard let value else { return fallback }
        return SettingsDataSyncMode(rawValue: value) ?? fallback
    }
}

private extension Array {
    nonisolated var nonEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
