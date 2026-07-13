import Foundation

/// 서버 `brokerage` enum. Hyphen 실제 지원 목록과 대조 전이라 API 가이드의 10개 값을 그대로 둔다.
nonisolated enum BrokerageCode: String, Codable, Sendable {
    case kbSecurities = "KB_SECURITIES"
    case miraeAsset = "MIRAE_ASSET"
    case samsungSecurities = "SAMSUNG_SECURITIES"
    case nhInvestment = "NH_INVESTMENT"
    case koreaInvestment = "KOREA_INVESTMENT"
    case kiwoom = "KIWOOM"
    case shinhanSecurities = "SHINHAN_SECURITIES"
    case hanaSecurities = "HANA_SECURITIES"
    case tossSecurities = "TOSS_SECURITIES"
    case kakaopaySecurities = "KAKAOPAY_SECURITIES"

    /// 로컬 `AccountInstitution.id` → 서버 enum 매핑. 은행 등 매핑 대상이 아니면 nil.
    init?(institutionID: String) {
        switch institutionID {
        case AccountInstitution.koreaInvestmentID:
            self = .koreaInvestment
        case "mirae":
            self = .miraeAsset
        case "kiwoom":
            self = .kiwoom
        case "samsung_securities":
            self = .samsungSecurities
        case "nh_invest":
            self = .nhInvestment
        case "kb_securities":
            self = .kbSecurities
        case "hana_securities":
            self = .hanaSecurities
        case "shinhan_invest":
            self = .shinhanSecurities
        case "toss_securities":
            self = .tossSecurities
        default:
            return nil
        }
    }
}

nonisolated enum BrokerageConnectionStatus: String, Codable, Sendable {
    case connected = "CONNECTED"
    case disconnected = "DISCONNECTED"
}

nonisolated struct BrokerageConnection: Equatable, Sendable {
    let connectionId: String
    let brokerage: BrokerageCode?
    let status: BrokerageConnectionStatus
    let connectedAt: Date?
}
