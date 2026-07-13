import Foundation

struct OnboardingNewsPreviewItem: Identifiable, Hashable {
    let id: String
    let sectorID: String
    let title: String
    let summary: String
}

enum InterestSector: String, CaseIterable, Identifiable, Codable {
    case semiconductor
    case energy
    case finance
    case defense
    case bio
    case mobility
    case realEstate
    case ev
    case ai

    var id: String { rawValue }

    static var onboardingOptions: [InterestSector] {
        [.semiconductor, .energy, .finance, .defense, .bio, .mobility]
    }

    var title: String {
        switch self {
        case .semiconductor: return "반도체"
        case .energy: return "에너지"
        case .finance: return "금융"
        case .defense: return "방산"
        case .bio: return "바이오"
        case .mobility: return "모빌리티"
        case .realEstate: return "부동산"
        case .ev: return "2차전지"
        case .ai: return "AI·소프트웨어"
        }
    }

    var emoji: String {
        switch self {
        case .semiconductor: return "💾"
        case .energy: return "⚡️"
        case .finance: return "🏦"
        case .defense: return "🛡️"
        case .bio: return "🧬"
        case .mobility: return "🚗"
        case .realEstate: return "🏠"
        case .ev: return "🔋"
        case .ai: return "🤖"
        }
    }

    var colorHex: String {
        switch self {
        case .semiconductor: return "8B5CF6"
        case .energy: return "10B981"
        case .finance: return "3B82F6"
        case .defense: return "EF4444"
        case .bio: return "F59E0B"
        case .mobility: return "0EA5E9"
        case .realEstate: return "06B6D4"
        case .ev: return "5BBBFF"
        case .ai: return "9F7CFF"
        }
    }

    var description: String {
        switch self {
        case .semiconductor:
            return "보조금·수출 규제와 금리 변화에 민감한 대표 성장 섹터"
        case .energy:
            return "원자재와 전력 인프라 정책이 수익률에 바로 반영돼요"
        case .finance:
            return "금리 경로와 대출 규제 변화에 빠르게 반응해요"
        case .defense:
            return "예산 확대와 수출 승인 뉴스가 수급에 크게 작동해요"
        case .bio:
            return "임상·허가 정책과 세제 변화 영향을 자주 받아요"
        case .mobility:
            return "전기차·물류·운송 정책 변화가 수급에 연결돼요"
        case .realEstate:
            return "대출 규제와 공급 정책이 리츠·건설주에 연결돼요"
        case .ev:
            return "보조금과 공급망 뉴스가 배터리 ETF 흐름을 흔들어요"
        case .ai:
            return "반도체·클라우드 투자 정책과 맞물려 강하게 움직여요"
        }
    }

    var previewItems: [OnboardingNewsPreviewItem] {
        switch self {
        case .semiconductor:
            return [
                OnboardingNewsPreviewItem(id: "semi-1", sectorID: id, title: "미국 반도체 장비 규제 재검토", summary: "장비주와 나스닥 성장 ETF 변동성 확대 가능성"),
                OnboardingNewsPreviewItem(id: "semi-2", sectorID: id, title: "국내 반도체 세액공제 확대 논의", summary: "설비 투자 수혜 기대감으로 공급망 종목 관심 확대")
            ]
        case .energy:
            return [
                OnboardingNewsPreviewItem(id: "energy-1", sectorID: id, title: "전력망 투자 예산 증액 검토", summary: "재생에너지 ETF와 전력 인프라 종목 모멘텀 강화"),
                OnboardingNewsPreviewItem(id: "energy-2", sectorID: id, title: "원유 비축 정책 조정 가능성", summary: "원자재 가격 민감도가 높은 에너지주 주목")
            ]
        case .finance:
            return [
                OnboardingNewsPreviewItem(id: "finance-1", sectorID: id, title: "기준금리 인하 시점 발언 주목", summary: "은행·보험 ETF 수익성 전망 재평가"),
                OnboardingNewsPreviewItem(id: "finance-2", sectorID: id, title: "가계대출 규제 미세 조정 검토", summary: "대형 금융주와 배당 ETF 방어력 체크 필요")
            ]
        case .defense:
            return [
                OnboardingNewsPreviewItem(id: "defense-1", sectorID: id, title: "국방 예산 증액안 국회 논의", summary: "방산 수출 기대감과 장비주 강세 재점화 가능성"),
                OnboardingNewsPreviewItem(id: "defense-2", sectorID: id, title: "우방국 공동개발 계약 추진", summary: "중장기 수주 파이프라인 가시성 확대")
            ]
        case .bio:
            return [
                OnboardingNewsPreviewItem(id: "bio-1", sectorID: id, title: "바이오 특례 상장 요건 개편 검토", summary: "중소형 바이오 변동성 확대 구간 진입 가능성"),
                OnboardingNewsPreviewItem(id: "bio-2", sectorID: id, title: "혁신 신약 지원 예산 확대 발표", summary: "R&D 중심 바이오 ETF에 긍정 신호")
            ]
        case .mobility:
            return [
                OnboardingNewsPreviewItem(id: "mobility-1", sectorID: id, title: "전기차 보조금 기준 조정 논의", summary: "완성차와 배터리 ETF의 단기 수급 변화 가능성"),
                OnboardingNewsPreviewItem(id: "mobility-2", sectorID: id, title: "도심 물류 규제 완화 검토", summary: "운송·플랫폼 관련 종목 모멘텀 점검 필요")
            ]
        case .realEstate:
            return [
                OnboardingNewsPreviewItem(id: "realestate-1", sectorID: id, title: "주택 공급 로드맵 추가 발표 예고", summary: "건설·리츠 관련 뉴스 해석 우선순위 상승"),
                OnboardingNewsPreviewItem(id: "realestate-2", sectorID: id, title: "대출 규제 완화 범위 재검토", summary: "부동산 금융과 리츠 ETF 동반 반응 가능성")
            ]
        case .ev:
            return [
                OnboardingNewsPreviewItem(id: "ev-1", sectorID: id, title: "배터리 보조금 기준 세부안 공개", summary: "2차전지 공급망 ETF 수급 변화 예상"),
                OnboardingNewsPreviewItem(id: "ev-2", sectorID: id, title: "핵심 광물 관세 협상 진전", summary: "소재주 원가 부담 완화 기대감 반영")
            ]
        case .ai:
            return [
                OnboardingNewsPreviewItem(id: "ai-1", sectorID: id, title: "AI 데이터센터 전력 지원책 논의", summary: "클라우드·반도체 동반 수혜 기대"),
                OnboardingNewsPreviewItem(id: "ai-2", sectorID: id, title: "공공 AI 도입 예산 확대 발표", summary: "소프트웨어·인프라 ETF 관심도 상승")
            ]
        }
    }

    var recommendedAssetSymbols: [String] {
        switch self {
        case .semiconductor: return ["SOXX"]
        case .energy: return ["ICLN"]
        case .finance: return ["KODEX 은행 ETF"]
        case .defense: return ["ARIRANG K방산Fn"]
        case .bio: return ["XBI"]
        case .mobility: return ["DRIV"]
        case .realEstate: return ["VNQ"]
        case .ev: return ["LIT"]
        case .ai: return ["BOTZ"]
        }
    }
}
