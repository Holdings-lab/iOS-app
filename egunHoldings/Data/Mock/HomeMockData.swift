import SwiftUI

struct HomeMockData {
    static let profile = InvestorProfile(
        dateText: "2026년 3월 24일 화요일",
        greeting: "안녕하세요, 투자자님",
        initials: "JK"
    )

    static let weeklyEvents: [HomePolicyEvent] = [
        HomePolicyEvent(id: 1, date: "3/24", day: "오늘", title: "한은 금통위", symbol: "building.columns.fill", color: .electricBlue),
        HomePolicyEvent(id: 2, date: "3/25", day: "내일", title: "반도체 보조금 발표", symbol: "cpu.fill", color: .policyPurple),
        HomePolicyEvent(id: 3, date: "3/26", day: "수", title: "에너지 전환 정책", symbol: "bolt.fill", color: .emerald),
        HomePolicyEvent(id: 4, date: "3/27", day: "목", title: "미 FOMC 의사록", symbol: "building.columns.fill", color: .policyAmber),
        HomePolicyEvent(id: 5, date: "3/28", day: "금", title: "미 PCE 지수 발표", symbol: "arrow.up.right", color: .policyCoral)
    ]

    static let snapshot = PortfolioSnapshot(
        amountText: "₩13,550,000",
        changePercentText: "+1.2%",
        insightText: "오늘 자산이 1.2% 올랐어요. 주로 반도체 보조금 기대감으로 SOXX가 끌어올렸어요."
    )

    static let trendPoints: [PortfolioTrendPoint] = [
        PortfolioTrendPoint(id: 1, dateLabel: "3/17", value: 1240),
        PortfolioTrendPoint(id: 2, dateLabel: "3/18", value: 1265),
        PortfolioTrendPoint(id: 3, dateLabel: "3/19", value: 1258),
        PortfolioTrendPoint(id: 4, dateLabel: "3/20", value: 1310),
        PortfolioTrendPoint(id: 5, dateLabel: "3/21", value: 1342),
        PortfolioTrendPoint(id: 6, dateLabel: "3/22", value: 1328),
        PortfolioTrendPoint(id: 7, dateLabel: "3/24", value: 1355)
    ]

    static let trendMarkers: [PortfolioMarker] = [
        PortfolioMarker(id: 1, dateLabel: "3/19", title: "금리 동결", value: 1258),
        PortfolioMarker(id: 2, dateLabel: "3/21", title: "반도체법 통과", value: 1342)
    ]

    static let eventDetails: [Int: PolicyEventDetail] = [
        1: PolicyEventDetail(
            id: 1,
            summaryBullets: [
                "📢 한국은행이 기준금리를 유지할지 조정할지 결정하는 회의를 열어요.",
                "💡 물가와 경기 상황을 같이 보면서 ‘돈의 가격’을 정하는 과정이에요.",
                "📅 발표 직후 예금·대출 금리 방향에 대한 시장 반응이 크게 나올 수 있어요."
            ],
            sentiment: .neutral,
            impactScore: 54,
            impactSummary: "당장 큰 변화보다, 다음 달 금융상품 금리 조건 변화에 먼저 영향이 갈 가능성이 높아요.",
            walletImpacts: [
                WalletImpactItem(id: 1, title: "예금/적금족", message: "신규 가입 상품의 우대금리 조건이 바뀔 수 있어요.", symbol: "banknote.fill"),
                WalletImpactItem(id: 2, title: "주식 투자자", message: "은행·성장주 간 자금 이동이 생길 수 있어요.", symbol: "chart.line.uptrend.xyaxis"),
                WalletImpactItem(id: 3, title: "대출 보유자", message: "변동금리 대출은 고지 금리 변화를 꼭 확인하세요.", symbol: "creditcard.fill")
            ],
            keyTerms: [
                KeyTermItem(id: 1, term: "금통위", plainDescription: "한국의 기준금리를 정하는 회의예요."),
                KeyTermItem(id: 2, term: "기준금리", plainDescription: "은행 금리의 기준이 되는 핵심 숫자예요.")
            ],
            watchPoint: "발표문에서 ‘물가’보다 ‘경기 둔화’를 더 강조하는지 확인해보세요. 이후 금리 방향 힌트가 됩니다."
        ),
        2: PolicyEventDetail(
            id: 2,
            summaryBullets: [
                "📢 정부가 반도체 기업 투자비 일부를 지원하는 2차 보조금 계획을 내놔요.",
                "💡 공장·장비 투자 부담을 줄여 생산 경쟁력을 높이는 게 목표예요.",
                "📅 이달 말부터 신청을 받아 집행 속도가 빠를 것으로 예상돼요."
            ],
            sentiment: .positive,
            impactScore: 82,
            impactSummary: "반도체 투자 심리가 개선되면 관련 ETF와 장비·소재 종목이 먼저 반응할 가능성이 커요.",
            walletImpacts: [
                WalletImpactItem(id: 1, title: "예금/적금족", message: "직접 영향은 적지만, 투자상품 관심이 커질 수 있어요.", symbol: "banknote.fill"),
                WalletImpactItem(id: 2, title: "주식 투자자", message: "반도체 장비·소재·ETF로 수급이 몰릴 수 있어요.", symbol: "chart.line.uptrend.xyaxis"),
                WalletImpactItem(id: 3, title: "대출 보유자", message: "주식 비중 확대 전 이자 부담부터 먼저 점검하세요.", symbol: "creditcard.fill")
            ],
            keyTerms: [
                KeyTermItem(id: 1, term: "보조금", plainDescription: "정부가 비용 일부를 대신 내주는 지원금이에요."),
                KeyTermItem(id: 2, term: "CAPEX", plainDescription: "공장·장비 같은 큰 투자 지출을 뜻해요.")
            ],
            watchPoint: "지원 총액이 5조 원을 넘는지, 그리고 실제 집행 시작 시점이 언제인지가 핵심입니다."
        ),
        3: PolicyEventDetail(
            id: 3,
            summaryBullets: [
                "📢 정부가 에너지 전환 속도를 높이기 위한 세부 정책을 공개해요.",
                "💡 재생에너지 비중 확대와 인프라 투자 일정이 핵심 포인트예요.",
                "📅 지원 대상 산업이 확정되면 관련 기업 주가 변동이 커질 수 있어요."
            ],
            sentiment: .positive,
            impactScore: 76,
            impactSummary: "클린에너지 관련 ETF와 인프라 기업의 중기 기대감이 커질 수 있어요.",
            walletImpacts: [
                WalletImpactItem(id: 1, title: "예금/적금족", message: "직접 수익 영향은 작지만 시장 변동성은 커질 수 있어요.", symbol: "banknote.fill"),
                WalletImpactItem(id: 2, title: "주식 투자자", message: "태양광·ESS·전력망 관련 종목이 주목받을 수 있어요.", symbol: "chart.line.uptrend.xyaxis"),
                WalletImpactItem(id: 3, title: "대출 보유자", message: "변동성 구간에서는 레버리지 투자 비중을 줄이세요.", symbol: "creditcard.fill")
            ],
            keyTerms: [
                KeyTermItem(id: 1, term: "에너지 믹스", plainDescription: "전기 생산원을 어떻게 섞을지 정한 비율이에요."),
                KeyTermItem(id: 2, term: "재생에너지", plainDescription: "태양광·풍력처럼 다시 쓸 수 있는 에너지원이에요.")
            ],
            watchPoint: "재생에너지 목표 비율 상향 폭과 송전망 투자 금액이 시장 기대치보다 큰지 확인하세요."
        ),
        4: PolicyEventDetail(
            id: 4,
            summaryBullets: [
                "📢 미국 연준(Fed) 회의에서 어떤 논의가 오갔는지 세부 내용이 공개돼요.",
                "💡 ‘언제 금리를 내릴지’에 대한 힌트가 문장에 담겨 있는 문서예요.",
                "📅 공개 직후 달러·미국채 금리·나스닥 변동성이 커질 수 있어요."
            ],
            sentiment: .neutral,
            impactScore: 49,
            impactSummary: "직접 정책 발표보다 ‘뉘앙스’가 중요해, 단기 변동성 대응이 핵심입니다.",
            walletImpacts: [
                WalletImpactItem(id: 1, title: "예금/적금족", message: "국내 금리엔 간접 영향이라 즉시 체감은 제한적이에요.", symbol: "banknote.fill"),
                WalletImpactItem(id: 2, title: "주식 투자자", message: "미국 기술주 방향에 따라 국내 성장주도 흔들릴 수 있어요.", symbol: "chart.line.uptrend.xyaxis"),
                WalletImpactItem(id: 3, title: "대출 보유자", message: "환율 변동이 커지면 생활비 체감 부담도 달라질 수 있어요.", symbol: "creditcard.fill")
            ],
            keyTerms: [
                KeyTermItem(id: 1, term: "의사록", plainDescription: "회의에서 무슨 이야기를 했는지 적은 기록이에요."),
                KeyTermItem(id: 2, term: "연준", plainDescription: "미국의 중앙은행 역할을 하는 기관이에요.")
            ],
            watchPoint: "문서에서 ‘inflation(물가)’와 ‘growth(성장)’ 중 어떤 단어가 더 강하게 표현되는지 보세요."
        ),
        5: PolicyEventDetail(
            id: 5,
            summaryBullets: [
                "📢 미국의 핵심 물가 지표(PCE)가 발표돼요.",
                "💡 연준이 금리 결정을 할 때 중요하게 보는 물가 온도계예요.",
                "📅 수치가 예상보다 높으면 금리 인하 기대가 늦춰질 수 있어요."
            ],
            sentiment: .caution,
            impactScore: 38,
            impactSummary: "물가가 높게 나오면 주식시장 조정 가능성이 커져 방어적 포지션이 유리할 수 있어요.",
            walletImpacts: [
                WalletImpactItem(id: 1, title: "예금/적금족", message: "고금리 유지 가능성으로 예적금 매력은 유지될 수 있어요.", symbol: "banknote.fill"),
                WalletImpactItem(id: 2, title: "주식 투자자", message: "성장주 변동성이 확대될 수 있으니 분할 대응이 좋아요.", symbol: "chart.line.uptrend.xyaxis"),
                WalletImpactItem(id: 3, title: "대출 보유자", message: "금리 하락 기대가 미뤄질 수 있어 상환 계획 점검이 필요해요.", symbol: "creditcard.fill")
            ],
            keyTerms: [
                KeyTermItem(id: 1, term: "PCE", plainDescription: "미국의 소비자 지출 물가 지표예요."),
                KeyTermItem(id: 2, term: "컨센서스", plainDescription: "시장 참가자들의 평균 예상치예요.")
            ],
            watchPoint: "실제 수치가 컨센서스를 0.2%p 이상 웃도는지 확인하세요. 시장 반응이 커질 가능성이 높아요."
        )
    ]

    static let userAssetProfile = UserAssetProfile(
        holdings: [
            UserHoldingItem(id: 1, name: "SOXX", category: .etf, weightPercent: 18),
            UserHoldingItem(id: 2, name: "ICLN", category: .etf, weightPercent: 12),
            UserHoldingItem(id: 3, name: "KODEX 은행 ETF", category: .etf, weightPercent: 9),
            UserHoldingItem(id: 4, name: "정기예금", category: .depositSavings, weightPercent: 34),
            UserHoldingItem(id: 5, name: "주택담보대출", category: .loan, weightPercent: 27)
        ]
    )

    static let chartGridValues: [Double] = [1260, 1300, 1340]
}
