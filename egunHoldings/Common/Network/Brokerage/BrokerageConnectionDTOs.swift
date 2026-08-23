import Foundation

// MARK: - POST /api/users/{userId}/brokerage-connections

/// 한국투자증권 모의투자로 전환하면서 앱키·시크릿은 서버가 보유하게 됐다.
/// 클라이언트는 어떤 증권사에 연결할지만 알리고, 토큰 발급·계좌 매핑은 전부 서버가 처리한다.
nonisolated struct BrokerageConnectionCreateRequestDTO: Encodable {
    let brokerage: String
}

// MARK: - POST(201) / GET / DELETE 공통 응답

// DELETE 응답은 connectionId·status만 내려오므로 나머지 필드는 옵셔널로 둔다.
nonisolated struct BrokerageConnectionResponseDTO: Decodable {
    let connectionId: String
    let brokerage: String?
    let status: String
    let connectedAt: Date?
    /// 서버가 붙여준 모의투자 계좌번호. 화면에는 마스킹해서 노출한다.
    let accountNumber: String?

    func toDomain() -> BrokerageConnection {
        BrokerageConnection(
            connectionId: connectionId,
            brokerage: brokerage.flatMap(BrokerageCode.init(rawValue:)),
            status: BrokerageConnectionStatus(rawValue: status) ?? .disconnected,
            connectedAt: connectedAt,
            accountNumber: accountNumber
        )
    }
}
