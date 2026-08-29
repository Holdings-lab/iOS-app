import Foundation

enum AccountCategory: String, Codable {
    case securities
    case bank
}

struct AccountInstitution: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let emoji: String
    let accentHex: String
    let category: AccountCategory
    let isPopular: Bool
}

extension AccountInstitution {
    static let koreaInvestmentID = "korea_investment"

    var displaySubtitle: String {
        switch id {
        case Self.koreaInvestmentID:
            return "시뮬레이션 계정으로 실제 포트폴리오 반응을 미리 확인할 수 있어요"
        case "kiwoom":
            return "국내 주식 중심 보유 계좌를 연결하기 좋아요"
        case "samsung_securities":
            return "연금과 ETF 비중을 함께 보기 좋은 증권사예요"
        case "mirae":
            return "해외 ETF와 성장 섹터 비중 확인에 유리해요"
        case "nh_invest":
            return "배당과 방어 자산 흐름을 함께 체크할 수 있어요"
        default:
            return "설정 후 보유 종목 기준으로 정책 영향도를 계산해드려요"
        }
    }
}
