import Foundation

nonisolated enum NewsroomRemoteURL {
    static func parse(_ value: String?) -> URL? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty, let url = URL(string: value),
              let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
}
