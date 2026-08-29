import Foundation

// MARK: - /api/accounts

nonisolated struct BrokerAccountSnapshotDTO: Decodable, Sendable {
    let accountProductCode: String?
}

// POST/GET 계좌 응답에서 온보딩이 사용하는 최소 필드만 디코딩한다.
nonisolated struct BrokerageConnectionResponseDTO: Decodable {
    let accountId: Int64
    let brokerName: String
    let status: String
    /// 서버가 붙여준 모의투자 계좌번호. 화면에는 마스킹해서 노출한다.
    let accountNumber: String?
    let accountSnapshot: BrokerAccountSnapshotDTO?

    func toDomain() -> BrokerageConnection {
        BrokerageConnection(
            accountId: accountId,
            brokerage: BrokerageCode(rawValue: brokerName),
            status: BrokerageConnectionStatus(rawValue: status) ?? .disconnected,
            accountNumber: accountNumber,
            accountProductCode: accountSnapshot?.accountProductCode
        )
    }
}

nonisolated struct BrokerageSyncResponseDTO: Decodable {
    let status: String
}
