import Foundation
import Testing
@testable import egunHoldings

struct SettingsAPIContractTests {
    @Test("설정 홈과 알림 변경이 서버 계약을 그대로 사용한다")
    func usesSettingsEndpointsAndPayloads() async throws {
        let queue = SettingsRequestQueue(responses: [
            envelope(resultJSON: settingsJSON),
            envelope(resultJSON: #"{"policyChangeAlert":false,"briefingTime":"09:00"}"#),
            envelope(resultJSON: #"{"policyChangeAlert":false,"briefingTime":"10:00"}"#),
            envelope(resultJSON: #"{"status":"SENT","message":"테스트 알림을 보냈어요."}"#),
        ])
        let repository = LiveSettingsRepository(apiClient: SettingsAPIClient(queue: queue))

        let settings = try await repository.fetchSettings()
        _ = try await repository.updateNotifications(policyChangeAlert: false, briefingTime: nil)
        _ = try await repository.updateNotifications(policyChangeAlert: nil, briefingTime: "10:00")
        let testNotification = try await repository.sendTestNotification()
        let requests = await queue.recordedRequests()

        #expect(settings.user.nickname == "김폴시그널")
        #expect(settings.investment.connectedAccounts.expiredCount == 1)
        #expect(settings.investment.interests.count == 5)
        #expect(testNotification.status == "SENT")
        #expect(requests.map(\.path) == [
            "/api/me/settings",
            "/api/me/settings/notifications",
            "/api/me/settings/notifications",
            "/api/me/notifications/test",
        ])
        #expect(requests.map(\.method.rawValue) == ["GET", "PATCH", "PATCH", "POST"])
        #expect(try requestBody(requests[1]) == #"{"policyChangeAlert":false}"#)
        #expect(try requestBody(requests[2]) == #"{"briefingTime":"10:00"}"#)
    }

    private var settingsJSON: String {
        #"{"user":{"nickname":"김폴시그널","email":"investor@polsignal.kr","avatarText":"김"},"notifications":{"policyChangeAlert":true,"briefingTime":"09:00"},"investment":{"goal":{"code":"HOME_PURCHASE","label":"내 집 마련"},"connectedAccounts":{"count":2,"expiredCount":1},"interests":{"count":5}}}"#
    }

    private func envelope(resultJSON: String) -> Data {
        Data(#"{"isSuccess":true,"code":"SUCCESS-200","message":"OK","result":\#(resultJSON)}"#.utf8)
    }

    private func requestBody(_ endpoint: Endpoint) throws -> String {
        let data = try #require(endpoint.body)
        return try #require(String(data: data, encoding: .utf8))
    }
}

private enum SettingsRequestError: Error {
    case missingResponse
}

private actor SettingsRequestQueue {
    private var responses: [Data]
    private var requests: [Endpoint] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func nextResponse(for endpoint: Endpoint) throws -> Data {
        requests.append(endpoint)
        guard !responses.isEmpty else { throw SettingsRequestError.missingResponse }
        return responses.removeFirst()
    }

    func recordedRequests() -> [Endpoint] { requests }
}

private struct SettingsAPIClient: APIClient {
    let queue: SettingsRequestQueue

    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try await queue.nextResponse(for: endpoint)
        return try NetworkJSONCoding.makeDecoder().decode(type, from: data)
    }
}
