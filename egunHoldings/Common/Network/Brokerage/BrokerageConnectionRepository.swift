import Foundation

nonisolated enum BrokerageConnectionError: LocalizedError {
    case unsupportedInstitution
    case missingAccount
    case connectionRejected
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedInstitution:
            return "현재는 한국투자증권 모의투자만 연결할 수 있어요."
        case .missingAccount:
            return "서버에서 연결된 계좌 정보를 받지 못했어요."
        case .connectionRejected:
            return "모의투자 계좌가 연결 상태가 아니에요."
        case .syncFailed:
            return "모의투자 계좌 동기화에 실패했어요."
        }
    }
}

/// 서버 환경에 있는 KIS 모의투자 계좌를 현재 JWT 사용자에게 연결한다.
/// 앱은 증권사 자격증명을 수집하거나 전송하지 않는다.
nonisolated protocol BrokerageConnectionRepositoryProtocol: Sendable {
    func connectKISDemoAccount(institutionID: String) async throws -> BrokerageConnection
    func sync(accountId: Int64) async throws
}

nonisolated struct LiveBrokerageConnectionRepository: BrokerageConnectionRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func connectKISDemoAccount(institutionID: String) async throws -> BrokerageConnection {
        guard BrokerageCode(institutionID: institutionID) == .kis else {
            throw BrokerageConnectionError.unsupportedInstitution
        }

        if let existing = try await connectedKISAccount() {
            return existing
        }

        let accounts = try await apiClient.requestResult(
            BackendEndpoint.linkBrokerAccount(),
            as: [BrokerageConnectionResponseDTO].self
        )
        guard let account = accounts.first?.toDomain() else {
            throw BrokerageConnectionError.missingAccount
        }
        guard account.status == .connected else {
            throw BrokerageConnectionError.connectionRejected
        }
        return account
    }

    func sync(accountId: Int64) async throws {
        let response = try await apiClient.requestResult(
            BackendEndpoint.syncBrokerAccount(accountId: accountId),
            as: BrokerageSyncResponseDTO.self
        )
        guard response.status == "SUCCESS" else {
            throw BrokerageConnectionError.syncFailed
        }
    }

    private func connectedKISAccount() async throws -> BrokerageConnection? {
        let accounts = try await apiClient.requestResult(
            BackendEndpoint.brokerAccounts(),
            as: [BrokerageConnectionResponseDTO].self
        )
        return accounts.map { $0.toDomain() }.first { account in
            account.brokerage == .kis && account.status == .connected
        }
    }
}
