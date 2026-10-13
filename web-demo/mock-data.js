// Mirrors TodayMockData, NewsroomDigestMockData and AppMockData in the iOS app.
const mockAsOf = new Date();
mockAsOf.setHours(6, 0, 0, 0);
const mockGeneratedAt = new Date(mockAsOf.getTime() - 86400000);
const mockSourceTime = hours => new Date(mockAsOf.getTime() - hours * 3600000).toISOString();
window.__EGUN_MOCK__ = {
  schemaVersion: 1,
  source: "ios-mock",
  user: { userId: 1, userName: "정책고수", onboardingCompleted: true },
  todayNewsMock: [
    { id: "art_1", title: "NVIDIA Q1 실적 발표", summary: "매출 +85%, 가이던스 상향 조정", ticker: "QQQ" },
    { id: "art_2", title: "한국은행 기준금리 동결", summary: "금리 동결 — 금융섹터 영향 제한적", ticker: "XLF" },
    { id: "art_3", title: "필라델피아 반도체 지수 강세", summary: "AI 수요 지속에 반도체 업종 전반 강세", ticker: "SOXX" },
    { id: "art_4", title: "미 국채 금리 하락", summary: "금리 하락 시 금융주 순이자마진 압박 우려", ticker: "XLF" }
  ],
  cachedBrokerBalance: {
    broker: "KIS", environment: "MOCK", totalEvaluationAmount: 134820000,
    stockEvaluationAmount: 126420000, cashAmount: 8400000,
    totalPurchaseAmount: 120000000, totalProfitLossAmount: 14820000,
    holdings: [
      { symbol: "381180", name: "TIGER 미국필라델피아반도체나스닥", productType: "ETF", quantity: 500, currencyCode: "KRW", purchaseAmount: 53000000, evaluationAmount: 62500000, profitLossAmount: 9500000, profitLossRate: 17.9 },
      { symbol: "QQQ", name: "Invesco QQQ Trust Series 1", productType: "ETF", quantity: 100, currencyCode: "KRW", purchaseAmount: 29500000, evaluationAmount: 35000000, profitLossAmount: 5500000, profitLossRate: 18.6 },
      { symbol: "KODEX", name: "KODEX 미국S&P500TR", productType: "ETF", quantity: 750, currencyCode: "KRW", purchaseAmount: 26625000, evaluationAmount: 28920000, profitLossAmount: 2295000, profitLossRate: 8.6 }
    ]
  },
  responses: {
    "/api/daily-briefing": { isSuccess: true, code: "SUCCESS-200", result: { dailyChangePct: 0.4, drawdownPct: -3, status: "NORMAL", message: "포트폴리오가 고점 근처를 유지하고 있어요. 오늘은 특별히 확인할 게 없어요." } },
    "/api/holdings": { isSuccess: true, code: "SUCCESS-200", result: { holdings: [
      { ticker: "QQQ", name: "Invesco QQQ Trust", weightPct: 34 },
      { ticker: "SOXX", name: "iShares Semiconductor", weightPct: 22 },
      { ticker: "XLF", name: "Financial Select SPDR", weightPct: 15 },
      { ticker: "USD", name: "달러 예금", weightPct: 15 },
      { ticker: "KRW", name: "국내 예금", weightPct: 14 }
    ] } },
    "/api/goal-progress": { isSuccess: true, code: "SUCCESS-200", result: { goalLabel: "은퇴자금", progressPct: 64, scheduleStatus: "AHEAD", scheduleNote: "예정보다 2개월 빠름" } },
    "/api/newsroom": { isSuccess: true, code: "SUCCESS-200", result: {
      header: { title: "뉴스룸", asOfAt: mockAsOf.toISOString(), subtitle: "다음 업데이트는 내일 아침이에요" },
      section: { title: "내 보유 종목", itemCount: 4 }, footer: { message: "오늘 브리핑은 여기까지예요" }, emptyState: null, errorState: null,
      holdings: [
        { ticker: "AAPL", name: "Apple", weightPct: 18, briefingType: "Hero", dailyChangePct: -0.6, headline: "애플, 인도 생산 비중 확대 계획 보도", summary: "공급망 다변화 움직임이 이어졌지만 회사의 공식 발표는 아직 없어요.", detailPath: "/api/users/1/newsroom/AAPL" },
        { ticker: "NVDA", name: "NVIDIA", weightPct: 12, briefingType: "Compact", dailyChangePct: 1.8, headline: "엔비디아, 데이터센터 매출 예상 상회 속 다음 분기 전망 제시", summary: null, detailPath: "/api/users/1/newsroom/NVDA" },
        { ticker: "MSFT", name: "Microsoft", weightPct: 9, briefingType: "Compact", dailyChangePct: 0.2, headline: "AI 수요 대응을 위한 데이터센터 투자가 이어질 예정이에요.", summary: null, detailPath: "/api/users/1/newsroom/MSFT" },
        { ticker: "QQQ", name: "Invesco QQQ Trust", weightPct: 35, briefingType: "Quiet", headline: "13일째 특이사항 없음", summary: "계속 지켜보고 있어요" }
      ]
    } },
    "/api/newsroom/AAPL": { isSuccess: true, code: "SUCCESS-200", result: { stock: { ticker: "AAPL", name: "Apple", weightPct: 18, dailyChangePct: -0.6 }, headline: "애플, 인도 생산 비중 확대 계획 보도", imageUrl: null, aiJudgement: { title: "AI는 이렇게 판단했어요", headline: "공급망 다변화는 장기 이슈라서 단일 보도만으로 단기 방향을 판단하기는 어려워요.", reason: "머신러닝은 상승 확률 49% 수준으로 방향성을 잡지 못하고 있습니다. 인도 생산 비중 확대는 수년 단위로 진행되는 구조적 변화라 단기 주가에 반영되는 폭이 크지 않고, 회사의 공식 발표가 아직 없어 보도 자체의 확실성도 낮은 편입니다.", alignment: "MIXED", usedNewsUrls: [], disclaimer: "본 내용은 투자 판단의 근거가 아닙니다.", generatedAt: mockGeneratedAt.toISOString() }, summary: { body: "애플이 인도 내 생산 비중을 늘리는 방안을 검토 중이라는 보도가 있었어요. 회사의 공식 발표는 아직 없어요.", findings: ["인도 생산 비중 확대를 검토 중이라는 보도가 나왔어요"] }, sources: [{ newsId: "aapl-1", title: "Apple weighs expanding India production share", publisher: "Reuters", publishedAt: mockSourceTime(11.3), thumbnailUrl: null, url: "https://example.com/aapl-1" }], footer: { asOfAt: mockAsOf.toISOString(), aiNotice: "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요." } } },
    "/api/newsroom/NVDA": { isSuccess: true, code: "SUCCESS-200", result: { stock: { ticker: "NVDA", name: "NVIDIA", weightPct: 12, dailyChangePct: 1.8 }, headline: "엔비디아, 데이터센터 매출 예상 상회 속 다음 분기 전망 제시", imageUrl: null, aiJudgement: { title: "AI는 이렇게 판단했어요", headline: "뉴스 분위기는 긍정적이지만 실적 발표 직후에는 변동성이 커질 수 있는 구간이에요.", reason: "머신러닝은 상승 확률 58% 수준의 완만한 신호를 포착하고 있습니다. 데이터센터 매출이 컨센서스를 웃돈 점은 긍정적이지만, 다음 분기 가이던스가 예상 범위 안에 머물러 추가 상향 여지가 제한적입니다. 실적 발표 직후 구간은 차익 실현 물량이 나오기 쉬워 방향성보다 변동성 확대에 무게를 둡니다.", alignment: "POSITIVE", usedNewsUrls: [], disclaimer: "본 내용은 투자 판단의 근거가 아닙니다.", generatedAt: mockGeneratedAt.toISOString() }, summary: { body: "엔비디아가 2분기 실적을 발표했어요. 데이터센터 부문 매출이 시장 예상을 웃돌았다는 보도가 이어졌고, 다음 분기 가이던스는 예상 범위 안이었어요.", findings: ["데이터센터 매출이 시장 컨센서스를 상회했다고 발표", "3분기 가이던스는 애널리스트 예상 범위 내로 제시"] }, sources: [{ newsId: "nvda-1", title: "Nvidia tops data center revenue estimates in Q2", publisher: "Reuters", publishedAt: mockSourceTime(7.8), thumbnailUrl: null, url: "https://example.com/nvda-1" }, { newsId: "nvda-2", title: "Nvidia guidance lands in line with expectations", publisher: "Yahoo Finance", publishedAt: mockSourceTime(3.9), thumbnailUrl: null, url: "https://example.com/nvda-2" }], footer: { asOfAt: mockAsOf.toISOString(), aiNotice: "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요." } } },
    "/api/newsroom/MSFT": { isSuccess: true, code: "SUCCESS-200", result: { stock: { ticker: "MSFT", name: "Microsoft", weightPct: 9, dailyChangePct: 0.2 }, headline: "마이크로소프트, 클라우드 인프라 투자 계획 재확인", imageUrl: null, aiJudgement: { title: "AI는 이렇게 판단했어요", headline: "투자 확대는 수요 기대와 비용 부담을 함께 봐야 하는 신호예요.", reason: "인프라 투자 재확인은 클라우드·AI 수요가 견조하다는 신호로 읽히지만, 동시에 감가상각비 증가로 이어져 단기 영업이익률에는 부담으로 작용합니다. 두 요인이 상쇄되는 구간이라 뚜렷한 방향을 제시하기 어렵습니다.", alignment: "NEUTRAL", usedNewsUrls: [], disclaimer: "본 내용은 투자 판단의 근거가 아닙니다.", generatedAt: mockGeneratedAt.toISOString() }, summary: { body: "마이크로소프트가 클라우드와 AI 수요 대응을 위한 인프라 투자 계획을 재확인했어요.", findings: [] }, sources: [{ newsId: "msft-1", title: "Microsoft reiterates cloud infrastructure plans", publisher: "Bloomberg", publishedAt: mockSourceTime(5.2), thumbnailUrl: null, url: "https://example.com/msft-1" }], footer: { asOfAt: mockAsOf.toISOString(), aiNotice: "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요." } } }
  }
};
