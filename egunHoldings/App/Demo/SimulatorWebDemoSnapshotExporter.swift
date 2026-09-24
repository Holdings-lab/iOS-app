import Foundation

/// Exports the currently signed-in simulator user's read-only demo data.
/// Only an explicit DEBUG launch argument enables this path. Credentials are
/// used for requests in memory and are never written to the exported file.
nonisolated enum SimulatorWebDemoSnapshotExporter {
    static func exportIfRequested() async {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-export-web-demo-snapshot") else { return }
        guard let session = KeychainAuthSessionStore().load() else { return }

        var responses: [String: Any] = [:]
        let paths = [
            "/api/daily-briefing",
            "/api/holdings",
            "/api/goal-progress",
            "/api/portfolio",
            "/api/newsroom"
        ]

        for path in paths {
            if let payload = await fetch(path: path, token: session.token) {
                responses[path] = redact(payload)
            }
        }

        if let newsroom = responses["/api/newsroom"] as? [String: Any] {
            let result = (newsroom["result"] as? [String: Any]) ?? newsroom
            let holdings = (result["holdings"] as? [[String: Any]]) ?? []
            for holding in holdings.prefix(12) {
                guard let ticker = holding["ticker"] as? String,
                      holding["briefingType"] as? String != "Quiet",
                      let encoded = ticker.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                else { continue }
                let path = "/api/newsroom/\(encoded)"
                if let payload = await fetch(path: path, token: session.token) {
                    responses[path] = redact(payload)
                }
            }
        }

        var snapshot: [String: Any] = [
            "schemaVersion": 1,
            "source": "simulator-session",
            "capturedAt": ISO8601DateFormatter().string(from: Date()),
            "user": [
                "userId": session.userId.map { $0 as Any } ?? NSNull(),
                "userName": session.userName,
                "onboardingCompleted": session.onboardingCompleted
            ],
            "responses": responses
        ]

        if let balance = session.brokerBalanceSnapshot,
           let data = try? JSONEncoder().encode(balance),
           let object = try? JSONSerialization.jsonObject(with: data) {
            snapshot["cachedBrokerBalance"] = redact(object)
        }

        guard let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted, .sortedKeys]),
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }

        try? data.write(to: documents.appendingPathComponent("web-demo-snapshot.json"), options: .atomic)
        #endif
    }

    #if DEBUG
    private static func fetch(path: String, token: String) async -> Any? {
        guard let url = URL(string: path, relativeTo: NetworkConfiguration.backendBaseURL)?.absoluteURL else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 35

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let status = (response as? HTTPURLResponse)?.statusCode,
              (200..<300).contains(status)
        else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private static let sensitiveKeys: Set<String> = [
        "token", "accesstoken", "refreshtoken", "password", "email",
        "accountnumber", "accountproductcode", "appkey", "appsecret",
        "credentials", "authorization"
    ]

    private static func redact(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { output, entry in
                let normalized = entry.key.lowercased().filter { $0.isLetter || $0.isNumber }
                guard !sensitiveKeys.contains(normalized) else { return }
                output[entry.key] = redact(entry.value)
            }
        }
        if let array = value as? [Any] {
            return array.map(redact)
        }
        return value
    }
    #endif
}
