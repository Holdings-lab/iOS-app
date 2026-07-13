import Foundation

nonisolated enum BrokerageConnectionError: Error {
    /// 서버 공개키가 아직 클라이언트에 배포되지 않아 크리덴셜을 암호화할 수 없는 상태
    case serverKeyUnavailable
    /// 서버 brokerage enum에 매핑되지 않는 기관
    case unsupportedInstitution
}

/// 온보딩 Step 7·설정 탭 "연결된 계좌"·오늘 탭 빈 상태 CTA가 공유하는 증권사 연동 리포지토리.
/// 연동 추가/해제 성공 시 ①②③ 응답의 `isAccountLinked`가 서버에서 전환된다.
nonisolated protocol BrokerageConnectionRepositoryProtocol: Sendable {
    func connect(
        userId: Int64,
        institutionID: String,
        credential: BrokerageCredentialPayloadDTO
    ) async throws -> BrokerageConnection

    func fetchConnections(userId: Int64) async throws -> [BrokerageConnection]

    func disconnect(userId: Int64, connectionId: String) async throws -> BrokerageConnection
}

nonisolated struct LiveBrokerageConnectionRepository: BrokerageConnectionRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func connect(
        userId: Int64,
        institutionID: String,
        credential: BrokerageCredentialPayloadDTO
    ) async throws -> BrokerageConnection {
        guard let brokerage = BrokerageCode(institutionID: institutionID) else {
            throw BrokerageConnectionError.unsupportedInstitution
        }

        guard let cipher = BrokerageCredentialCipher.makeFromConfiguration() else {
            throw BrokerageConnectionError.serverKeyUnavailable
        }

        let encrypted = try cipher.encrypt(credential)
        let body = try NetworkJSONCoding.encodeJSON(
            BrokerageConnectionCreateRequestDTO(
                brokerage: brokerage.rawValue,
                keyId: encrypted.keyId,
                encryptedKey: encrypted.encryptedKey,
                iv: encrypted.iv,
                ciphertext: encrypted.ciphertext
            )
        )

        let response = try await apiClient.requestResult(
            BackendEndpoint.createBrokerageConnection(userId: userId, body: body),
            as: BrokerageConnectionResponseDTO.self
        )
        return response.toDomain()
    }

    func fetchConnections(userId: Int64) async throws -> [BrokerageConnection] {
        let response = try await apiClient.requestResult(
            BackendEndpoint.brokerageConnections(userId: userId),
            as: [BrokerageConnectionResponseDTO].self
        )
        return response.map { $0.toDomain() }
    }

    func disconnect(userId: Int64, connectionId: String) async throws -> BrokerageConnection {
        let response = try await apiClient.requestResult(
            BackendEndpoint.deleteBrokerageConnection(userId: userId, connectionId: connectionId),
            as: BrokerageConnectionResponseDTO.self
        )
        return response.toDomain()
    }
}
