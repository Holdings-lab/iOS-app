import Foundation

/// 현재 서버가 연결을 허용하는 증권사 코드.
nonisolated enum BrokerageCode: String, Codable, Sendable {
    case kis = "KIS"

    /// 로컬 `AccountInstitution.id` → 서버 enum 매핑. 은행 등 매핑 대상이 아니면 nil.
    init?(institutionID: String) {
        switch institutionID {
        case AccountInstitution.koreaInvestmentID:
            self = .kis
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
    let accountId: Int64
    let brokerage: BrokerageCode?
    let status: BrokerageConnectionStatus
    let accountNumber: String?
    let accountProductCode: String?
}
