import Foundation

nonisolated enum RiskProfileConsistency {
    /// 안정형인데 -30%까지 감내하거나, 공격형인데 -10%까지만 감내하는 조합만 불일치로 본다.
    static func isConsistent(profile: InvestmentProfile, tolerance: MaxDrawdownTolerance) -> Bool {
        if profile == .conservative, tolerance.percentValue >= 30 { return false }
        if profile == .aggressive, tolerance.percentValue <= 10 { return false }
        return true
    }

    static func buildConfirmMessage(profile: InvestmentProfile) -> String {
        let direction = profile == .aggressive ? "좁은" : "넓은"
        return "선택하신 손실 허용 범위가 일반적인 \(profileLabel(profile)) 성향보다 \(direction) 편이에요.\n이대로 진행할까요?"
    }

    private static func profileLabel(_ profile: InvestmentProfile) -> String {
        switch profile {
        case .conservative: return "안정형"
        case .balanced: return "중립형"
        case .aggressive: return "공격형"
        }
    }
}
