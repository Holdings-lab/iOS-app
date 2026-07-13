import Foundation

// MARK: - POST /api/users/{userId}/brokerage-connections

nonisolated struct BrokerageConnectionCreateRequestDTO: Encodable {
    let brokerage: String
    let keyId: String
    let encryptedKey: String
    let iv: String
    let ciphertext: String
}

/// 암호화 전 평문 크리덴셜. 이 JSON이 AES-GCM으로 암호화되어 `ciphertext`에 실린다.
nonisolated struct BrokerageCredentialPayloadDTO: Encodable, Sendable {
    let loginId: String
    let loginPassword: String
    let accountPassword: String
}

// MARK: - POST(201) / GET / DELETE 공통 응답

// DELETE 응답은 connectionId·status만 내려오므로 나머지 필드는 옵셔널로 둔다.
nonisolated struct BrokerageConnectionResponseDTO: Decodable {
    let connectionId: String
    let brokerage: String?
    let status: String
    let connectedAt: Date?

    func toDomain() -> BrokerageConnection {
        BrokerageConnection(
            connectionId: connectionId,
            brokerage: brokerage.flatMap(BrokerageCode.init(rawValue:)),
            status: BrokerageConnectionStatus(rawValue: status) ?? .disconnected,
            connectedAt: connectedAt
        )
    }
}
