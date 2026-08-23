import Foundation

nonisolated enum BrokerageConnectionError: Error {
    /// 서버 brokerage enum에 매핑되지 않는 기관
    case unsupportedInstitution
}

/// 온보딩 Step 7·설정 탭 "연결된 계좌"·오늘 탭 빈 상태 CTA가 공유하는 증권사 연동 리포지토리.
/// 연동 추가/해제 성공 시 ①②③ 응답의 `isAccountLinked`가 서버에서 전환된다.
///
/// 한국투자증권 모의투자 구조에서는 앱키·시크릿이 서버에만 존재하므로 클라이언트가 보낼
/// 크리덴셜이 없다. `connect`는 "이 사용자를 모의투자 계좌에 붙여달라"는 요청에 가깝다.
nonisolated protocol BrokerageConnectionRepositoryProtocol: Sendable {
    func connect(userId: Int64, institutionID: String) async throws -> BrokerageConnection

    func fetchConnections(userId: Int64) async throws -> [BrokerageConnection]

    func disconnect(userId: Int64, connectionId: String) async throws -> BrokerageConnection
}

nonisolated struct LiveBrokerageConnectionRepository: BrokerageConnectionRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func connect(userId: Int64, institutionID: String) async throws -> BrokerageConnection {
        guard let brokerage = BrokerageCode(institutionID: institutionID) else {
            throw BrokerageConnectionError.unsupportedInstitution
        }

        let body = try NetworkJSONCoding.encodeJSON(
            BrokerageConnectionCreateRequestDTO(brokerage: brokerage.rawValue)
        )

        let response = try await apiClient.requestResult(
            BackendEndpoint.createBrokerageConnection(body: body),
            as: BrokerageConnectionResponseDTO.self
        )
        return response.toDomain()
    }

    func fetchConnections(userId: Int64) async throws -> [BrokerageConnection] {
        let response = try await apiClient.requestResult(
            BackendEndpoint.brokerageConnections(),
            as: [BrokerageConnectionResponseDTO].self
        )
        return response.map { $0.toDomain() }
    }

    func disconnect(userId: Int64, connectionId: String) async throws -> BrokerageConnection {
        let response = try await apiClient.requestResult(
            BackendEndpoint.deleteBrokerageConnection(connectionId: connectionId),
            as: BrokerageConnectionResponseDTO.self
        )
        return response.toDomain()
    }
}
