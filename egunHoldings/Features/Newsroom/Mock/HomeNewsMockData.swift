import Foundation

enum HomeNewsMockData {
    static let items: [PolicyNewsItem] = [
        PolicyNewsItem(
            id: "semiconductor-subsidy-round2",
            category: .semiconductor,
            publishedAt: Date().addingTimeInterval(-2 * 60 * 60),
            title: "미 상무부, 반도체 보조금 2차 배분 시작... 삼성·SK 수혜 전망",
            summary: "SOXX와 장비주 ETF 쪽으로 매수 기대가 붙으면서 단기 탄력이 살아날 가능성이 있어요.",
            sourceName: "Reuters",
            sourceURL: URL(string: "https://www.reuters.com"),
            relatedTickers: ["SOXX", "SMH"],
            sentiment: .positive
        ),
        PolicyNewsItem(
            id: "bok-rate-hold-preview",
            category: .interestRate,
            publishedAt: Date().addingTimeInterval(-4 * 60 * 60),
            title: "한은 기준금리 동결 가능성 확대... 은행주·채권 ETF는 숨 고르기",
            summary: "당장 급변보다는 발언 톤이 더 중요해서 금융주와 채권 ETF 반응은 제한적일 수 있어요.",
            sourceName: "연합인포맥스",
            sourceURL: URL(string: "https://news.einfomax.co.kr"),
            relatedTickers: ["KODEX 은행 ETF"],
            sentiment: .neutral
        ),
        PolicyNewsItem(
            id: "energy-transition-roadmap",
            category: .energy,
            publishedAt: Date().addingTimeInterval(-6 * 60 * 60),
            title: "탄소중립 로드맵 수정안 발표... 재생에너지 설비 투자 확대",
            summary: "ICLN과 전력 인프라 테마가 함께 움직일 가능성이 커서 분산 매수 관점이 살아 있어요.",
            sourceName: "Bloomberg",
            sourceURL: URL(string: "https://www.bloomberg.com"),
            relatedTickers: ["ICLN"],
            sentiment: .positive
        ),
        PolicyNewsItem(
            id: "pce-cooling-watch",
            category: .macro,
            publishedAt: Date().addingTimeInterval(-8 * 60 * 60),
            title: "미 PCE 발표 앞두고 관망세 확대... 성장주 추격매수는 숨 고르기",
            summary: "당장 행동보다 결과 확인이 우선이라 지금은 제목만 체크해도 충분한 이슈예요.",
            sourceName: "WSJ",
            sourceURL: URL(string: "https://www.wsj.com"),
            relatedTickers: [],
            sentiment: .neutral
        ),
        PolicyNewsItem(
            id: "bank-deposit-rate-cut",
            category: .finance,
            publishedAt: Date().addingTimeInterval(-10 * 60 * 60),
            title: "시중은행 예금 금리 인하 검토... 신규 예치 전략 재점검 필요",
            summary: "예금과 대출을 함께 가진 사용자라면 금리 숫자보다 변경 시점만 체크해도 되는 브리핑이에요.",
            sourceName: "매일경제",
            sourceURL: URL(string: "https://www.mk.co.kr"),
            relatedTickers: [],
            sentiment: .caution
        ),
        PolicyNewsItem(
            id: "ai-export-guidance",
            category: .ai,
            publishedAt: Date().addingTimeInterval(-12 * 60 * 60),
            title: "EU, 생성형 AI 수출 가이드라인 공개... 플랫폼 기업은 규정 해석 대기",
            summary: "보유 ETF와 직접 연결되는 비중은 낮아 지금은 규제 방향만 확인해도 충분해요.",
            sourceName: "Financial Times",
            sourceURL: URL(string: "https://www.ft.com"),
            relatedTickers: [],
            sentiment: .neutral
        ),
        PolicyNewsItem(
            id: "shipping-carbon-levy",
            category: .energy,
            publishedAt: Date().addingTimeInterval(-14 * 60 * 60),
            title: "해운 탄소부담금 논의 재개... 운임 영향은 내년 이후 확인 가능",
            summary: "해운·물류 직접 보유가 없다면 당장 포트폴리오 액션으로 연결할 필요는 낮아요.",
            sourceName: "한국경제",
            sourceURL: URL(string: "https://www.hankyung.com"),
            relatedTickers: [],
            sentiment: .caution
        )
    ]

    static let insights: [String: PolicyNewsInsight] = [
        "semiconductor-subsidy-round2": PolicyNewsInsight(
            articleID: "semiconductor-subsidy-round2",
            headline: "반도체 설비투자 지원 기대가 살아나면서 관련 ETF 심리 개선에 우호적인 기사예요.",
            generatedAt: Date(),
            sourceName: "Reuters",
            sourceURL: URL(string: "https://www.reuters.com"),
            articleSummary: [
                "미국 정부의 반도체 투자 지원금 2차 배분이 시작되면서 생산능력 확대 기대가 다시 살아났어요.",
                "지원 속도가 빠르면 장비·소재 공급망 기업까지 수급이 번질 가능성이 커요.",
                "다만 실제 수혜 기업 확정 전까지는 뉴스 헤드라인에 따라 가격 변동성이 크게 출렁일 수 있어요."
            ],
            portfolioHeadline: "SOXX 보유 비중이 있는 사용자에게는 단기 모멘텀보다 분할 대응 계획이 더 중요한 기사예요.",
            portfolioBullets: [
                "현재 보유한 SOXX 비중이 기사 모멘텀에 가장 직접적으로 연결될 가능성이 있어요.",
                "헤드라인만 보고 바로 비중을 늘리기보다, 실제 집행 일정이 확인된 뒤 나눠서 접근하는 편이 안정적이에요.",
                "대출 비중이 있는 사용자는 공격적으로 추격 매수하기보다 현금 여력을 먼저 점검하는 편이 좋아요."
            ],
            actionChecklist: [
                "지원 총액과 실제 집행 시작 시점을 기사 원문에서 다시 확인하기",
                "SOXX, SMH 같은 반도체 ETF의 당일 거래대금이 평소보다 급증하는지 보기",
                "이미 오른 구간이라면 목표 비중을 정해두고 분할 매수 원칙 유지하기"
            ],
            riskNotes: [
                "정책 초안과 실제 집행 발표 사이에 시간이 길어지면 기대감이 빠르게 식을 수 있어요.",
                "반도체 섹터는 환율과 미국 금리 민감도도 높아서 단일 뉴스만으로 방향을 확정하기 어려워요."
            ],
            disclaimer: "이 시트는 기사 해설을 돕기 위한 참고 정보이며 투자 자문이 아니에요."
        ),
        "bok-rate-hold-preview": PolicyNewsInsight(
            articleID: "bok-rate-hold-preview",
            headline: "이번 기사는 금리 결정 자체보다 발표문 문구와 이후 시장 해석이 더 중요한 상황을 다뤄요.",
            generatedAt: Date(),
            sourceName: "연합인포맥스",
            sourceURL: URL(string: "https://news.einfomax.co.kr"),
            articleSummary: [
                "시장에서는 금리 동결 가능성을 높게 보고 있어서 숫자 자체는 상당 부분 선반영된 상태예요.",
                "관건은 한은이 물가와 경기 중 어느 쪽을 더 강조하느냐예요.",
                "은행주, 채권 ETF, 원화 환율이 발표 직후 미세하게 다른 방향으로 반응할 수 있어요."
            ],
            portfolioHeadline: "예적금과 금융 ETF가 섞여 있는 포트폴리오라면, 이번 기사는 리스크 관리 관점에서 읽는 편이 좋아요.",
            portfolioBullets: [
                "은행 ETF는 금리 수준보다도 향후 인하 시점 기대 변화에 더 민감하게 움직일 수 있어요.",
                "예적금 보유자는 새로 가입할 상품 금리 조건이 좋아질지 여부를 체크할 만해요.",
                "대출 보유 비중이 있다면 금리 하락 기대가 늦춰질 경우 월 상환 부담이 얼마나 유지되는지 함께 봐야 해요."
            ],
            actionChecklist: [
                "발표문에서 물가와 경기 관련 표현 강도를 비교하기",
                "발표 직후 원화 환율과 은행주 움직임을 같이 보기",
                "예적금 만기 예정이 가까우면 신규 금리 조건을 비교해보기"
            ],
            riskNotes: [
                "시장 예상과 크게 다르지 않으면 오히려 단기 재료 소멸로 변동성이 줄 수 있어요."
            ],
            disclaimer: "이 시트는 기사 해설을 돕기 위한 참고 정보이며 투자 자문이 아니에요."
        ),
        "energy-transition-roadmap": PolicyNewsInsight(
            articleID: "energy-transition-roadmap",
            headline: "정책 방향이 친환경 투자 확대 쪽으로 기울면서 클린에너지 테마 기대를 자극하는 기사예요.",
            generatedAt: Date(),
            sourceName: "Bloomberg",
            sourceURL: URL(string: "https://www.bloomberg.com"),
            articleSummary: [
                "재생에너지 설비와 전력망 투자 확대 계획이 기사 핵심이에요.",
                "정책 자금이 실제로 어디에 먼저 집행되는지가 종목 간 차이를 만들 가능성이 커요.",
                "태양광·풍력보다 송전망, 저장장치처럼 인프라 성격이 강한 영역이 먼저 주목받을 수 있어요."
            ],
            portfolioHeadline: "ICLN 보유자라면 기대감을 반영하되, 실제 수혜 산업이 ETF 구성과 얼마나 맞는지 확인이 필요해요.",
            portfolioBullets: [
                "ICLN은 정책 뉴스에 빠르게 반응할 수 있지만, 구성 종목이 광범위해서 체감 수혜는 분산될 수 있어요.",
                "뉴스 당일 급등 구간에서는 신규 매수보다 기존 비중 점검이 우선일 수 있어요.",
                "중장기 관점이라면 송전망 투자와 저장장치 정책이 이어지는지 후속 기사까지 확인하는 편이 좋아요."
            ],
            actionChecklist: [
                "지원 대상 산업이 태양광, 풍력, 저장장치 중 어디에 가까운지 확인하기",
                "ICLN 구성 종목 중 정책 수혜 후보가 얼마나 포함되는지 체크하기",
                "정책이 단발성 발표인지, 예산 반영 일정까지 이어지는지 보기"
            ],
            riskNotes: [
                "친환경 테마는 기대감만으로 먼저 오르고 실제 집행 지연 시 조정 폭이 커질 수 있어요."
            ],
            disclaimer: "이 시트는 기사 해설을 돕기 위한 참고 정보이며 투자 자문이 아니에요."
        )
    ]
}
