import Foundation

/// 로그인, 회원가입, 로컬 계정 조회에 사용하는 이메일 규칙.
nonisolated enum AuthEmailAddress {
    static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValid(_ value: String) -> Bool {
        let email = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return false }
        let parts = email.components(separatedBy: "@")
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domainParts = parts[1].split(separator: ".", omittingEmptySubsequences: false)
        return domainParts.count >= 2 && domainParts.allSatisfy { !$0.isEmpty }
    }
}
