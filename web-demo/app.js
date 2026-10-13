(() => {
  "use strict";

  const app = document.getElementById("app");
  const data = window.__EGUN_SNAPSHOT__;
  if (!data || data.source !== "simulator-session") {
    app.textContent = "현재 시뮬레이터 사용자의 데모 데이터를 찾지 못했습니다.";
    return;
  }
  const state = { tab: "today", detailTicker: null, overlay: null, liveToday: false, liveError: null,
    settingsPage: "root", settings: data.responses?.["/api/me/settings"]?.result || null, settingsError: null, settingsBusy: false, toast: null,
    policyChangeAlert: null, briefingTime: null, interestOptions: [], selectedInterests: [], accounts: null,
    goalCode: null, goalAmount: null, loginError: null };
  const number = new Intl.NumberFormat("ko-KR");
  const currency = (value, code = "KRW") => new Intl.NumberFormat(code === "KRW" ? "ko-KR" : "en-US", {
    style: "currency", currency: code, maximumFractionDigits: 0
  }).format(Number(value) || 0);
  const escapeHTML = value => String(value ?? "").replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);
  const safeURL = value => {
    try { const url = new URL(value); return ["http:", "https:"].includes(url.protocol) ? url.href : null; }
    catch { return null; }
  };
  const result = path => {
    const response = data.responses?.[path];
    return response?.result ?? response ?? null;
  };
  const percent = (value, digits = 1) => {
    if (value === null || value === undefined || Number.isNaN(Number(value))) return "—";
    const n = Number(value);
    return `${n > 0 ? "+" : ""}${n.toFixed(digits)}%`;
  };
  const wholePercent = value => `${Math.round(Number(value) || 0)}%`;
  const weightPercent = value => {
    const numberValue = Number(value);
    return Number.isFinite(numberValue) ? `${numberValue.toFixed(Number.isInteger(numberValue) ? 0 : 2)}%` : "—";
  };
  const firstSentence = value => {
    const text = String(value || "").trim();
    if (!text) return "";
    if (typeof Intl.Segmenter !== "function") return text.match(/^.*?[.!?](?:\s|$)/u)?.[0]?.trim() || text;
    return [...new Intl.Segmenter("ko", { granularity: "sentence" }).segment(text)]
      .map(item => item.segment.trim()).find(Boolean) || text;
  };
  const formatDate = () => new Intl.DateTimeFormat("ko-KR", { month: "long", day: "numeric", weekday: "long" }).format(new Date());
  const clockText = () => {
    const now = new Date();
    return `${now.getHours() % 12 || 12}:${String(now.getMinutes()).padStart(2, "0")}`;
  };
  const asOfDate = value => {
    if (!value) return "";
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    return new Intl.DateTimeFormat("ko-KR", { month: "long", day: "numeric", hour: "2-digit", minute: "2-digit", hour12: false }).format(date).replace("오전 ", "").replace("오후 ", "");
  };

  const icon = (name, className = "") => `<span class="icon icon-${name} ${className}" aria-hidden="true"></span>`;

  function cachedHoldings() {
    const holdings = data.cachedBrokerBalance?.holdings || [];
    const total = holdings.reduce((sum, holding) => sum + Math.max(0, Number(holding.evaluationAmount) || 0), 0);
    if (!total) return [];
    return holdings.map(holding => ({
      ticker: holding.symbol, name: holding.name,
      weightPct: Math.round(Number(holding.evaluationAmount) / total * 100)
    }));
  }

  function todayHoldings() {
    const source = data.cachedBrokerBalance && !state.liveToday
      ? cachedHoldings() : (result("/api/holdings")?.holdings || []);
    const top = source.filter(item => item.ticker !== "ETC").sort((a, b) => b.weightPct - a.weightPct).slice(0, 3);
    const remainder = Math.max(0, 100 - top.reduce((sum, item) => sum + Math.round(Number(item.weightPct) || 0), 0));
    return remainder ? [...top, { ticker: "ETC", name: "그 외 보유종목", weightPct: remainder }] : top;
  }

  function todayBriefing() {
    const live = result("/api/daily-briefing") || {};
    if (state.liveToday) return live;
    const balance = data.cachedBrokerBalance;
    const change = balance?.totalPurchaseAmount ? Math.round(balance.totalProfitLossAmount / balance.totalPurchaseAmount * 1000) / 10 : 0.4;
    return {
      drawdownPct: -3, dailyChangePct: change, status: "NORMAL",
      message: "포트폴리오가 고점 근처를 유지하고 있어요. 오늘은 특별히 확인할 게 없어요."
    };
  }

  function todayNews() {
    return (result("/api/newsroom")?.holdings || []).filter(holding => holding.briefingType !== "Quiet")
      .slice(0, 3).map(holding => ({ ticker: holding.ticker, title: holding.headline || holding.name, summary: holding.summary || "새로운 뉴스를 확인해 보세요." }));
  }

  function renderToday() {
    const briefing = todayBriefing();
    const goal = result("/api/goal-progress");
    const rows = todayHoldings();
    const news = todayNews();
    const drawdown = Math.round(Number(briefing.drawdownPct) || 0);
    const tolerance = Number(briefing.maxDrawdownTolerance);
    let message = briefing.message || "";
    if (state.liveToday && tolerance > 0) {
      const amount = Math.abs(Math.min(drawdown, 0));
      message = amount === 0 ? `포트폴리오가 현재 고점 수준이에요. 설정한 허용 낙폭 -${tolerance}%까지 여유가 있어요.`
        : amount < tolerance * .5 ? `최근 고점 대비 ${amount}% 하락했어요. 설정한 허용 낙폭 -${tolerance}% 안에서 움직이고 있어요.`
        : amount < tolerance ? `최근 고점 대비 ${amount}% 하락했어요. 설정한 허용 낙폭 -${tolerance}%에 가까워지고 있어요.`
        : `최근 고점 대비 ${amount}% 하락했어요. 설정한 허용 낙폭 -${tolerance}%에 도달했으니 포트폴리오를 점검해 보세요.`;
    }
    const goalProgress = Number(goal?.progressPct || 0);
    const goalStatus = goalProgress >= 100 ? "목표 달성" : ({ JUST_STARTED: "시작 단계", AHEAD: "빠르게 진행 중", ON_TRACK: "계획대로", BEHIND: "속도 점검" }[goal?.scheduleStatus] || "목표 진행 중");
    const colors = ["#3461fd", "#e8963c", "#2ea8a0", "#8b5cf6"];
    return `<div class="tab-content today-content">
      <header class="today-header"><div><p class="date-label">${escapeHTML(formatDate())}</p><h1>오늘</h1></div><div class="header-actions">
        <button class="round-icon" data-action="notifications" aria-label="알림">${icon("bell")}</button>
        <button class="round-icon" data-action="settings" aria-label="설정">${icon("gear")}</button>
      </div></header>
      ${!state.liveToday && !state.liveError ? `<div class="fallback-banner">${icon("alert")}<span>실시간 데이터를 불러오지 못했어요. 일부 값은 이전 또는 예시 데이터일 수 있습니다.</span></div>` : ""}
      ${state.liveError ? `<div class="fallback-banner">${icon("alert")}<span>${escapeHTML(state.liveError)} <button class="inline-link" data-action="login">실시간 연결</button></span></div>` : ""}
      <section class="card briefing-card"><div class="briefing-metric"><span class="eyebrow">고점 대비</span><strong>${drawdown > 0 ? "+" : ""}${drawdown}%</strong><span class="muted-pill">전일 대비 ${percent(briefing.dailyChangePct)}</span></div><p>${escapeHTML(message)}</p></section>
      <section class="card"><h2>보유 비중 Top 3</h2><div class="section-rule"></div><div class="today-holdings">${rows.map((row, index) => `<div class="today-holding"><div class="holding-line"><i class="dot" style="--dot:${colors[index % colors.length]}"></i><strong>${escapeHTML(row.ticker)}</strong><span class="truncate">${escapeHTML(row.name)}</span><b>${wholePercent(row.weightPct)}</b></div><div class="track"><span style="width:${Math.min(100, Number(row.weightPct) || 0)}%;background:${colors[index % colors.length]}"></span></div></div>`).join("")}</div></section>
      <button class="card goal-card card-button" data-action="asset"><div class="goal-top"><h2>목표 대비</h2><strong>${escapeHTML(goalStatus)}</strong></div><div class="track"><span style="width:${Math.min(100, goalProgress)}%"></span></div><div class="goal-bottom"><b>${goalProgress}%</b><span>${escapeHTML(goal?.goalLabel || "아직 목표가 없어요")} · ${escapeHTML(goal?.scheduleNote || "")}</span></div></button>
      <section class="card news-preview"><div class="section-head"><h2>보유종목 관련 뉴스</h2><button class="text-button" data-action="newsroom">더보기</button></div><div class="section-rule"></div>${news.length ? news.map(item => `<button class="preview-row" data-action="detail" data-ticker="${escapeHTML(item.ticker)}"><span class="ticker-chip">${escapeHTML(item.ticker)}</span><span class="preview-copy"><strong>${escapeHTML(item.title)}</strong><small>${escapeHTML(item.summary)}</small></span>${icon("chevron")}</button>`).join("") : `<p class="empty-copy">오늘은 보유 종목에 관한 새로운 소식이 없어요.</p>`}</section>
    </div>`;
  }

  function newsroomRows() {
    const content = result("/api/newsroom");
    return (content?.holdings || []).slice().sort((a, b) => {
      const rank = { Hero: 0, Compact: 1, Quiet: 2 };
      return (rank[a.briefingType] ?? 3) - (rank[b.briefingType] ?? 3) || (Number(b.weightPct) || 0) - (Number(a.weightPct) || 0);
    });
  }

  function renderNewsroom() {
    const content = result("/api/newsroom") || {};
    const rows = newsroomRows();
    const date = asOfDate(content.header?.asOfAt);
    const subtitle = [date && `${date} 기준`, content.header?.subtitle].filter(Boolean).join(" · ");
    if (content.errorState) return `<div class="tab-content newsroom-content"><h1>뉴스룸</h1><p class="subtitle">${escapeHTML(subtitle)}</p><div class="card centered-state"><h2>${escapeHTML(content.errorState.title)}</h2><p>${escapeHTML(content.errorState.summary)}</p><button class="primary-button" data-action="refresh">${escapeHTML(content.errorState.buttonLabel || "다시 시도")}</button></div></div>`;
    if (content.emptyState || !rows.length) return `<div class="tab-content newsroom-content"><h1>뉴스룸</h1><p class="subtitle">${escapeHTML(subtitle)}</p><div class="card centered-state"><h2>${escapeHTML(content.emptyState?.title || "맞춤 뉴스가 아직 없어요")}</h2><p>${escapeHTML(content.emptyState?.description || "보유 종목을 연결하면 관련 뉴스를 보여드려요.")}</p><button class="primary-button" data-action="asset">${escapeHTML(content.emptyState?.buttonLabel || "내 자산 보기")}</button></div></div>`;
    return `<div class="tab-content newsroom-content"><header><h1>뉴스룸</h1><p class="subtitle">${escapeHTML(subtitle || "보유 자산의 최근 소식을 하나의 브리핑으로 정리해요")}</p></header><h2 class="section-title">내 보유 종목</h2>
      <div class="newsroom-rows">${rows.map((holding, index) => {
        const quiet = holding.briefingType === "Quiet";
        const hero = !quiet && index === 0;
        const value = holding.dailyChangePct;
        return quiet ? `<div class="newsroom-row quiet-row"><span class="stock-logo">${escapeHTML(holding.ticker?.[0] || "?")}</span><span><strong>${escapeHTML(holding.ticker)} · 내 자산의 ${weightPercent(holding.weightPct)}</strong><small>특이사항 없음 · 계속 지켜보고 있어요</small></span></div>`
          : `<button class="newsroom-row ${hero ? "hero-row" : "compact-row"}" data-action="detail" data-ticker="${escapeHTML(holding.ticker)}"><span class="stock-logo">${escapeHTML(holding.ticker?.[0] || "?")}</span><div class="newsroom-copy"><div class="stock-head"><strong>${escapeHTML(holding.ticker)}</strong>${hero ? `<small>내 자산의 ${weightPercent(holding.weightPct)}</small>` : ""}</div><b>${escapeHTML(holding.headline || holding.name)}</b>${hero && holding.summary ? `<p>${escapeHTML(firstSentence(holding.summary))}</p>` : ""}<span class="stock-meta"><em class="${Number(value) < 0 ? "negative" : "positive"}">오늘 ${percent(value)}</em> 총자산 기준 ${weightPercent(holding.weightPct)}</span></div>${icon("chevron")}</button>`;
      }).join("")}</div><p class="market-note">오늘 등락은 최근 정규장 시세의 전일 종가 대비예요. 시세는 지연될 수 있어요.</p><div class="end-marker"><span></span>${escapeHTML(content.footer?.message || "오늘 브리핑은 여기까지예요")}<span></span></div></div>`;
  }

  function balance() {
    if (data.cachedBrokerBalance && !state.liveToday) return data.cachedBrokerBalance;
    const portfolio = result("/api/portfolio");
    if (!portfolio) return null;
    return {
      totalEvaluationAmount: portfolio.estimatedDepositAsset || Number(portfolio.totalValuationAmount || 0) + Number(portfolio.cashBalance || 0),
      stockEvaluationAmount: portfolio.totalValuationAmount, cashAmount: portfolio.cashBalance,
      totalPurchaseAmount: portfolio.totalPurchaseAmount, totalProfitLossAmount: portfolio.totalValuationGainLoss,
      holdings: (portfolio.positions || []).map(position => ({
        symbol: position.itemCode, name: position.itemName, productType: position.productType, quantity: position.quantity,
        currencyCode: position.currencyCode || "KRW", evaluationAmount: position.native?.valuationAmount ?? position.valuationAmount ?? position.krw?.valuationAmount ?? 0,
        profitLossAmount: position.native?.gainLoss ?? position.valuationGainLoss ?? position.krw?.gainLoss ?? 0, profitLossRate: position.profitRate
      }))
    };
  }

  function renderAsset() {
    const asset = balance();
    if (!asset) return `<div class="tab-content asset-content"><header class="asset-header"><div><p>포트폴리오</p><h1>내 자산</h1></div><button class="square-icon" data-action="connect" aria-label="계좌 연결">${icon("plus")}</button></header><div class="card centered-state"><h2>자산을 불러오지 못했어요</h2><button class="primary-button" data-action="refresh">다시 시도</button></div></div>`;
    const total = Number(asset.totalEvaluationAmount) || 0;
    const cash = Number(asset.cashAmount) || 0;
    const invested = Math.max(0, total - cash);
    const stockPct = total ? Math.round(invested / total * 100) : 0;
    const cashPct = Math.max(0, 100 - stockPct);
    const profit = Number(asset.totalProfitLossAmount) || 0;
    const profitRate = Number(asset.totalPurchaseAmount) ? profit / Number(asset.totalPurchaseAmount) * 100 : 0;
    const holdings = asset.holdings || [];
    const row = holding => {
      const amount = holding.currentPrice && holding.quantity ? Number(holding.currentPrice) * Number(holding.quantity) : holding.evaluationAmount;
      const code = holding.currencyCode || "KRW";
      return `<div class="asset-holding"><div class="asset-holding-left"><span class="asset-symbol">${escapeHTML(holding.symbol)}</span><strong>${escapeHTML(holding.name || holding.symbol)}</strong><small>${number.format(Number(holding.quantity) || 0)}주 보유</small></div><div class="asset-holding-right"><strong>${escapeHTML(currency(amount, code))}</strong><span class="${Number(holding.profitLossAmount) < 0 ? "negative" : "positive"}">${Number(holding.profitLossAmount) > 0 ? "+" : ""}${escapeHTML(currency(holding.profitLossAmount, code))} (${percent(holding.profitLossRate)})</span></div></div>`;
    };
    return `<div class="tab-content asset-content"><header class="asset-header"><div><p>포트폴리오</p><h1>내 자산</h1></div><button class="square-icon" data-action="connect" aria-label="계좌 연결">${icon("plus")}</button></header>
      <section class="asset-hero"><p>원화 환산 총 평가금액</p><strong>${escapeHTML(currency(total))}</strong><span>${profit > 0 ? "+" : ""}${escapeHTML(currency(profit))} (${percent(profitRate)}) 누적 수익</span><div class="asset-composition"><i style="width:${stockPct}%"></i><i style="width:${cashPct}%"></i></div><div class="asset-legend"><span><i></i>주식 ETF ${stockPct}%</span><span><i></i>현금 ${cashPct}%</span></div></section>
      <h2 class="asset-section-title">보유 종목</h2><section class="asset-holdings card">${holdings.map(row).join("")}${cash > 0 ? `<div class="asset-holding"><div class="asset-holding-left"><span class="asset-symbol cash-symbol">▣</span><strong>현금·예수금</strong><small>예수금 포함</small></div><div class="asset-holding-right"><strong>${escapeHTML(currency(cash))}</strong><span>—</span></div></div>` : ""}</section>
      <section class="card asset-profit"><div><span>총 수익</span><b class="${profit < 0 ? "negative" : "positive"}">${profit > 0 ? "+" : ""}${escapeHTML(currency(profit))}</b></div><div><span>누적 수익률</span><b>${percent(profitRate)}</b></div><div><span>투자 원금</span><b>${escapeHTML(currency(asset.totalPurchaseAmount))}</b></div></section>
    </div>`;
  }

  function renderDetail() {
    const ticker = state.detailTicker;
    const holding = newsroomRows().find(item => item.ticker === ticker) || { ticker, name: ticker };
    const detail = result(`/api/newsroom/${ticker}`) || {};
    const stock = detail.stock || holding;
    const image = safeURL(detail.imageUrl || detail.sources?.[0]?.thumbnailUrl);
    const judgement = detail.aiJudgement;
    const ai = typeof judgement === "string" ? { headline: judgement } : judgement;
    return `<div class="detail-page"><header class="detail-top"><button class="back-button" data-action="back" aria-label="뒤로">${icon("back")}</button><strong>${escapeHTML(ticker)}</strong><span></span></header><div class="detail-scroll"><div class="detail-stock"><span class="stock-logo">${escapeHTML(ticker[0])}</span><div><p><b>${escapeHTML(ticker)}</b> <span>${escapeHTML(stock.name || holding.name)}</span></p><strong class="${Number(stock.dailyChangePct ?? holding.dailyChangePct) < 0 ? "negative" : "positive"}">오늘 ${percent(stock.dailyChangePct ?? holding.dailyChangePct)}</strong><small>내 자산의 ${weightPercent(holding.weightPct ?? stock.weightPct)}${detail.footer?.asOfAt ? ` · ${escapeHTML(asOfDate(detail.footer.asOfAt))} 기준` : ""}</small></div></div><div class="section-rule"></div><h1>${escapeHTML(detail.headline || holding.headline || holding.name)}</h1>
      ${image ? `<img class="detail-image" src="${escapeHTML(image)}" alt="뉴스 대표 이미지">` : `<div class="image-empty">${icon("photo")}<span>이미지 없음</span></div>`}
      ${ai ? `<section class="detail-ai"><span class="detail-kicker">${escapeHTML(ai.title || "AI는 이렇게 판단했어요")}</span><h2>${escapeHTML(ai.headline)}</h2>${ai.reason ? `<p>${escapeHTML(ai.reason)}</p>` : ""}${ai.disclaimer ? `<small>${escapeHTML(ai.disclaimer)}</small>` : ""}</section>` : ""}
      ${detail.summary?.body ? `<p class="detail-body">${escapeHTML(detail.summary.body)}</p>` : holding.summary ? `<p class="detail-body">${escapeHTML(holding.summary)}</p>` : ""}
      ${detail.summary?.findings?.length ? `<section class="detail-findings"><h2>새로 알려진 내용</h2>${detail.summary.findings.map(finding => `<p>• ${escapeHTML(finding)}</p>`).join("")}</section>` : ""}
      ${detail.sources?.length ? `<section class="detail-sources"><h2>출처</h2>${detail.sources.map(source => `<a href="${escapeHTML(safeURL(source.url) || "#")}" target="_blank" rel="noopener noreferrer"><span><b>${escapeHTML(source.title)}</b><small>${escapeHTML(source.publisher)}${source.publishedAt ? ` · ${escapeHTML(asOfDate(source.publishedAt))}` : ""}</small></span>${icon("external")}</a>`).join("")}</section>` : ""}
      <p class="detail-disclaimer">${escapeHTML(detail.footer?.aiNotice || "AI가 여러 기사를 요약했어요. 원문과 다를 수 있어요.")}</p></div></div>`;
  }

  const goalLabels = { RETIREMENT: "은퇴 자금 마련", SEED_MONEY: "목돈(종잣돈) 모으기", SPARE_FUND: "여유자금 굴리기", HOUSE: "내 집 마련" };
  const goalAmounts = { RETIREMENT: 500000000, SEED_MONEY: 50000000, SPARE_FUND: 30000000, HOUSE: 300000000 };
  const goalRanges = { RETIREMENT: [100000000, 1500000000, 50000000], SEED_MONEY: [10000000, 300000000, 5000000],
    SPARE_FUND: [5000000, 200000000, 5000000], HOUSE: [50000000, 1000000000, 50000000] };
  const goalDescriptions = { RETIREMENT: "긴 호흡으로 은퇴 후 생활 자금을 쌓아가요", SEED_MONEY: "결혼, 창업 등 앞으로의 시작 자금을 준비해요",
    SPARE_FUND: "당장 쓸 일 없는 자금을 편하게 굴려봐요", HOUSE: "주택 구입 시점에 맞춰 자금을 준비해요" };
  const shortWon = amount => Number(amount) >= 100000000 ? `${Number(amount) / 100000000}억원` :
    Number(amount) >= 10000000 ? `${Number(amount) / 10000000}천만원` : currency(amount);
  const interestCatalog = [
    ["SEMICONDUCTOR", "반도체"], ["AI_PLATFORM", "AI · 플랫폼"], ["SECONDARY_BATTERY", "2차전지"],
    ["GREEN_ENERGY", "친환경 · 에너지"], ["FINANCE", "금융"], ["HEALTHCARE_BIO", "헬스케어 · 바이오"],
    ["CONSUMER_RETAIL", "소비재 · 리테일"], ["REAL_ESTATE_REIT", "부동산 · 리츠"]
  ].map(([code, label]) => ({ code, label }));
  const settingRow = (label, sub, action, glyph, right = icon("chevron"), danger = false) => `<button class="setting-row ${danger ? "setting-danger" : ""}" data-action="${action}"><span class="setting-glyph">${glyph}</span><span class="setting-copy"><strong>${escapeHTML(label)}</strong>${sub ? `<small>${escapeHTML(sub)}</small>` : ""}</span><span class="setting-right">${right}</span></button>`;
  const settingSection = (title, rows) => `<section class="setting-section"><h3>${escapeHTML(title)}</h3><div class="setting-group">${rows}</div></section>`;
  const settingsBack = title => `<header class="setting-nav"><button data-action="settings-back" aria-label="뒤로">${icon("back")}</button><strong>${escapeHTML(title)}</strong><span></span></header>`;

  function renderSettingsRoot() {
    const settings = state.settings;
    const user = settings?.user;
    const investment = settings?.investment;
    const count = Number(investment?.connectedAccounts?.count || 0);
    const expired = Number(investment?.connectedAccounts?.expiredCount || 0);
    const policyOn = state.policyChangeAlert ?? settings?.notifications?.policyChangeAlert ?? false;
    const time = state.briefingTime ?? settings?.notifications?.briefingTime ?? "09:00";
    return `<header class="setting-large-head"><div><small>계정 및 앱 관리</small><h2>설정</h2></div><button data-action="close-overlay" aria-label="설정 닫기">${icon("close")}</button></header>
      <div class="setting-scroll">
        ${state.settingsError ? `<p class="setting-notice">${escapeHTML(state.settingsError)} <button data-action="settings-retry">다시 시도</button></p>` : ""}
        ${expired ? `<button class="setting-issue" data-action="settings-accounts">연결된 계정 ${expired}개의 인증이 만료됐어요. <b>확인</b></button>` : ""}
        <button class="setting-profile" data-action="settings-accounts"><span class="setting-avatar">${escapeHTML((user?.nickname || data.user?.userName || "투")[0])}</span><span><strong>${escapeHTML(user?.nickname || data.user?.userName || "투자자")}</strong><em>균형형</em><small>${escapeHTML(user?.email || "실시간 연결 후 이메일 표시")}</small></span>${icon("chevron")}</button>
        ${settingSection("알림",
          settingRow("정책 변화 알림", "중요 정책 변화를 알려드려요", "settings-policy-toggle", icon("settings-bell"), `<span class="setting-switch ${policyOn ? "on" : ""}" role="switch" aria-checked="${policyOn}"></span>`) +
          `<div class="setting-row"><span class="setting-glyph">${icon("sun")}</span><span class="setting-copy"><strong>오늘 브리핑 시간</strong><small>선택한 시간에 오늘의 브리핑을 보내드려요</small></span><span class="setting-segments">${["08:00", "09:00", "10:00"].map(option => `<button data-action="settings-time" data-time="${option}" class="${time === option ? "selected" : ""}">${option.slice(0, 2)}시</button>`).join("")}</span></div>` +
          settingRow("테스트 알림 보내기", "기기에 알림이 도착하는지 확인해요", "settings-test", icon("settings-send")))}
        ${settingSection("투자 설정",
          settingRow("투자 목표", `${investment?.goal?.label || "아직 목표가 없어요"}${investment?.goal ? ` · ${shortWon(state.goalAmount || 500000000)}` : ""}`, "settings-goal", icon("settings-target")) +
          settingRow("연결 계좌", `${count}개${expired ? " · 주의 필요" : ""}`, "settings-accounts", icon("settings-account")) +
          settingRow("관심 정책", `${investment?.interests?.count ?? 0}개`, "settings-interests", icon("settings-policy")))}
        ${settingSection("계정",
          settingRow("이메일", user?.email || "—", "settings-email", icon("settings-email"), "") +
          settingRow("비밀번호 변경", "", "settings-password", icon("settings-lock")) +
          settingRow("로그아웃", "", "settings-logout", icon("settings-logout")) +
          settingRow("회원 탈퇴", "", "settings-delete", icon("settings-delete"), icon("chevron"), true) +
          settingRow("개인정보 처리방침", "", "settings-document", icon("settings-privacy")) +
          settingRow("이용약관", "", "settings-document", icon("settings-terms")))}
        <p class="setting-version">v3.1.0</p>
      </div>`;
  }

  function renderSettingsPage() {
    const page = state.settingsPage;
    if (page === "root") return renderSettingsRoot();
    if (page === "accounts") {
      const count = state.settings?.investment?.connectedAccounts?.count ?? 0;
      return `${settingsBack("연결된 계좌")}<div class="setting-scroll setting-subpage"><p class="setting-notice">조회 전용으로 연결돼요. 주문 권한은 요청하지 않고, 언제든 해제할 수 있어요.</p><div class="setting-group">${state.accounts?.length ? state.accounts.map(account => `<div class="setting-row"><span class="setting-glyph">${icon("settings-account")}</span><span class="setting-copy"><strong>${escapeHTML(account.brokerName || account.accountNickname || "연결 계좌")}</strong><small>${escapeHTML(account.status || "상태 확인 중")}${account.lastSyncedAt ? ` · ${escapeHTML(asOfDate(account.lastSyncedAt))} 동기화` : ""}</small></span></div>`).join("") : `<div class="setting-summary"><strong>연결된 계좌 ${count}개</strong><small>${state.accounts ? "서버에 연결된 계좌가 없어요." : "서버에서 계좌 상태를 확인 중이에요."}</small></div>`}</div></div>`;
    }
    if (page === "goal") {
      const code = state.goalCode || state.settings?.investment?.goal?.code || "RETIREMENT";
      const [min, max, step] = goalRanges[code];
      const amount = state.goalAmount || 500000000;
      const displayMax = Math.max(max, amount);
      return `${settingsBack("목표 설정")}<div class="setting-scroll setting-subpage"><h3>투자 목적</h3><div class="setting-choices">${Object.entries(goalLabels).map(([value, label]) => `<button class="${code === value ? "selected" : ""}" data-action="settings-goal-choice" data-value="${value}"><strong>${escapeHTML(label)}</strong><small>${escapeHTML(goalDescriptions[value])}</small></button>`).join("")}</div><h3>목표 금액</h3><div class="setting-amount-card"><strong id="setting-goal-value">${escapeHTML(shortWon(amount))}</strong><small>${amount === goalAmounts[code] ? "제안 금액 그대로" : "직접 조정한 금액"}</small><input type="range" min="${min}" max="${displayMax}" step="${step}" id="setting-goal-amount" value="${amount}" aria-label="목표 금액"><div><span>${shortWon(min)}</span><span>${shortWon(displayMax)}</span></div></div><button class="primary-button" data-action="settings-goal-save">저장</button></div>`;
    }
    if (page === "goal-confirm") return `${settingsBack("목표 설정")}<div class="setting-scroll setting-subpage"><div class="setting-group setting-summary"><strong>목표를 변경할까요?</strong><small>목표를 변경하면 진행 속도 추적이 처음부터 다시 시작돼요.</small></div><button class="primary-button" data-action="settings-goal-confirm-save">변경 저장</button><button class="setting-cancel" data-action="settings-goal">취소</button></div>`;
    if (page === "interests") {
      return `${settingsBack("관심 정책 카테고리")}<div class="setting-scroll setting-subpage"><p class="setting-notice">정책 신호 분석에 사용돼요. 1개 이상 5개 이하로 선택하세요.</p><div class="setting-choices">${state.interestOptions.map(item => `<button class="${state.selectedInterests.includes(item.code) ? "selected" : ""}" data-action="settings-interest-choice" data-value="${escapeHTML(item.code)}">${escapeHTML(item.label)}</button>`).join("")}</div><button class="primary-button" data-action="settings-interests-save">저장</button></div>`;
    }
    if (page === "password") return `${settingsBack("비밀번호 변경")}<form class="setting-scroll setting-subpage setting-form" id="settings-password-form"><label>현재 비밀번호<input name="currentPassword" type="password" required autocomplete="current-password"></label><label>새 비밀번호<input name="newPassword" type="password" required minlength="8" autocomplete="new-password"></label><label>새 비밀번호 확인<input name="confirmPassword" type="password" required minlength="8" autocomplete="new-password"></label><button class="primary-button" type="submit">변경하기</button></form>`;
    if (page === "logout" || page === "delete") return `${settingsBack(page === "logout" ? "로그아웃" : "회원 탈퇴")}<div class="setting-scroll setting-subpage"><div class="setting-group setting-summary"><strong>${page === "logout" ? "로그아웃할까요?" : "정말 탈퇴하시겠어요?"}</strong><small>${page === "logout" ? "다시 로그인하면 이어서 사용할 수 있어요." : "계정과 모든 설정, 연결된 계좌 정보가 삭제되고 되돌릴 수 없어요."}</small></div><button class="primary-button" data-action="settings-shared-account">${page === "logout" ? "로그아웃" : "탈퇴하기"}</button></div>`;
    return "";
  }

  function renderOverlay() {
    if (!state.overlay) return "";
    if (state.overlay === "login") return `<div class="overlay" data-action="close-overlay"><div class="sheet" role="dialog" aria-modal="true" aria-label="실시간 연결"><div class="sheet-handle"></div><div class="sheet-head"><h2>실시간 연결</h2><button data-action="close-overlay" aria-label="닫기">${icon("close")}</button></div><p>서버 계정으로 로그인하면 현재 데이터를 불러옵니다. 로그인 정보는 이 컴퓨터의 실행 중인 서버에만 전달됩니다.</p><form id="demo-login-form" class="setting-form"><label>이메일<input name="email" type="email" required autocomplete="username"></label><label>비밀번호<input name="password" type="password" required autocomplete="current-password"></label>${state.loginError ? `<p class="login-error">${escapeHTML(state.loginError)}</p>` : ""}<button class="primary-button" type="submit">연결하기</button></form></div></div>`;
    if (state.overlay === "connect") return `<div class="overlay" data-action="close-overlay"><div class="sheet" role="dialog" aria-modal="true" aria-label="계좌 연결"><div class="sheet-handle"></div><div class="sheet-head"><h2>계좌 연결</h2><button data-action="close-overlay" aria-label="닫기">${icon("close")}</button></div><p>한국투자증권 모의투자 계좌를 연결해 자산을 확인할 수 있어요.</p><div class="sheet-account"><strong>한국투자증권</strong><span>${data.cachedBrokerBalance ? "읽기 전용 계좌 연결됨" : "연결 전"}</span></div><button class="primary-button" data-action="close-overlay">확인</button></div></div>`;
    if (state.overlay === "notifications") return `<div class="overlay" data-action="close-overlay"><div class="sheet full-sheet" role="dialog" aria-modal="true" aria-label="알림"><div class="sheet-head"><h2>알림</h2><button data-action="close-overlay" aria-label="닫기">${icon("close")}</button></div><div class="centered-state"><h2>새로운 알림이 없어요</h2><p>새로운 분석이 도착하면 이곳에 알려드릴게요.</p></div></div></div>`;
    if (state.overlay === "settings") return `<div class="overlay settings-overlay"><div class="settings-sheet" role="dialog" aria-modal="true" aria-label="설정">${renderSettingsPage()}${state.toast ? `<div class="setting-toast" role="status">${escapeHTML(state.toast)}</div>` : ""}</div></div>`;
    return "";
  }

  function render() {
    const view = state.detailTicker ? renderDetail() : ({ today: renderToday, newsroom: renderNewsroom, asset: renderAsset })[state.tab]();
    app.innerHTML = `<div class="stage"><div class="device"><div class="status-bar"><strong>${clockText()}</strong><div class="system-icons"><span class="cellular">▪▪▪▪</span><span class="wifi">◕</span><span class="battery"><i></i></span></div></div><main class="screen" id="screen">${view}</main><nav class="tab-bar" aria-label="메인 탭">${[["today", "오늘", "sun"], ["newsroom", "뉴스룸", "news"], ["asset", "내 자산", "pie"]].map(([tab, label, symbol]) => `<button class="tab-item ${state.tab === tab ? "selected" : ""}" data-action="${tab}" aria-current="${state.tab === tab ? "page" : "false"}">${icon(symbol)}<span>${label}</span></button>`).join("")}</nav><div class="home-indicator"></div>${renderOverlay()}</div></div>`;
  }

  async function refreshLive() {
    state.overlay = null;
    state.liveError = null;
    if (location.protocol === "file:") {
      state.liveToday = false;
      state.liveError = "오프라인 파일입니다. 저장된 데모 데이터를 보여드려요.";
      render();
      return;
    }
    try {
      const paths = ["/api/daily-briefing", "/api/holdings", "/api/goal-progress", "/api/portfolio", "/api/newsroom"];
      const responses = await Promise.all(paths.map(async path => {
        const response = await fetch(path, { cache: "no-store" });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const body = await response.json();
        if (body.isSuccess !== true || !body.result) throw new Error(`Invalid response for ${path}`);
        return [path, body];
      }));
      for (const [path, response] of responses) data.responses[path] = response;
      const holdings = result("/api/newsroom")?.holdings || [];
      await Promise.all(holdings.filter(item => item.briefingType !== "Quiet").slice(0, 12).map(async item => {
        const path = `/api/newsroom/${encodeURIComponent(item.ticker)}`;
        const response = await fetch(path, { cache: "no-store" });
        if (response.ok) data.responses[path] = await response.json();
      }));
      state.liveToday = true;
    } catch { state.liveError = "실시간 데이터를 불러오지 못했어요. 저장된 데모 데이터를 보여드려요."; }
    render();
  }

  async function apiJSON(path, method = "GET", payload) {
    const response = await fetch(path, { method, cache: "no-store", headers: payload ? { "Content-Type": "application/json" } : {}, body: payload ? JSON.stringify(payload) : undefined });
    const body = await response.json();
    if (!response.ok || body.isSuccess === false) throw new Error(body.message || `HTTP ${response.status}`);
    return body.result ?? body;
  }

  function toast(message) {
    state.toast = message; render();
    setTimeout(() => { if (state.toast === message) { state.toast = null; render(); } }, 3000);
  }

  async function loadSettings() {
    state.settingsError = null;
    try {
      state.settings = await apiJSON("/api/me/settings");
      state.policyChangeAlert = state.settings.notifications.policyChangeAlert;
      state.briefingTime = state.settings.notifications.briefingTime;
    } catch (error) {
      state.settingsError = state.settings ? "저장된 설정을 보여드려요. 서버에 연결하면 최신 값으로 갱신됩니다." :
        error.message === "실시간 API를 사용할 수 없어요." ? "서버 연결이 필요해요. 저장된 화면을 보여드려요." : `설정을 불러오지 못했어요: ${error.message}`;
    }
    render();
  }

  async function saveNotification(payload) {
    if (state.settingsBusy) return;
    const previousPolicy = state.policyChangeAlert;
    const previousTime = state.briefingTime;
    state.settingsBusy = true;
    if (payload.policyChangeAlert !== undefined) state.policyChangeAlert = payload.policyChangeAlert;
    if (payload.briefingTime !== undefined) state.briefingTime = payload.briefingTime;
    render();
    try {
      const saved = await apiJSON("/api/me/settings/notifications", "PATCH", payload);
      state.policyChangeAlert = saved.policyChangeAlert;
      state.briefingTime = saved.briefingTime;
      if (state.settings) state.settings.notifications = saved;
      toast("알림 설정을 저장했어요");
    } catch (error) {
      state.policyChangeAlert = previousPolicy; state.briefingTime = previousTime;
      toast(`알림 설정을 저장하지 못했어요: ${error.message}`);
    } finally { state.settingsBusy = false; render(); }
  }

  async function openSettingsPage(page) {
    state.settingsPage = page; render();
    if (page === "accounts") {
      try { state.accounts = await apiJSON("/api/accounts"); }
      catch (error) { toast(`계좌 상태를 불러오지 못했어요: ${error.message}`); }
      render();
    }
    if (page === "interests") {
      try {
        const selected = await apiJSON("/api/me/settings/interests");
        state.selectedInterests = (selected.interests || []).map(item => item.code);
        state.interestOptions = interestCatalog;
        try { const options = await apiJSON("/api/interest-sectors"); if (options.options?.length) state.interestOptions = options.options; }
        catch { /* The deployed API currently omits the catalog route; use its known enum. */ }
      } catch (error) { toast(`관심 정책을 불러오지 못했어요: ${error.message}`); }
      render();
    }
  }

  async function handleSettingsAction(target) {
    const action = target.dataset.action;
    if (action === "settings-back") { state.settingsPage = state.settingsPage === "goal-confirm" ? "goal" : "root"; render(); return; }
    if (action === "settings-retry") { await loadSettings(); return; }
    if (action === "settings-email") return;
    if (action === "settings-document") { toast("문서 준비 중이에요"); return; }
    if (action === "settings-shared-account") { toast("공유 데모에서는 계정을 변경할 수 없어요"); return; }
    if (action === "settings-policy-toggle") { await saveNotification({ policyChangeAlert: !(state.policyChangeAlert ?? false) }); return; }
    if (action === "settings-time") { await saveNotification({ briefingTime: target.dataset.time }); return; }
    if (action === "settings-test") {
      if (state.settingsBusy) return;
      state.settingsBusy = true;
      try { const response = await apiJSON("/api/me/notifications/test", "POST"); toast(response.message || "테스트 알림을 보냈어요"); }
      catch (error) { toast(`테스트 알림을 보내지 못했어요: ${error.message}`); }
      finally { state.settingsBusy = false; }
      return;
    }
    if (action === "settings-goal-choice") { state.goalCode = target.dataset.value; state.goalAmount = goalAmounts[state.goalCode]; render(); return; }
    if (action === "settings-goal-save") {
      const amount = Number(document.getElementById("setting-goal-amount")?.value);
      if (!Number.isFinite(amount) || amount <= 0) { toast("목표 금액을 확인해 주세요"); return; }
      state.goalAmount = amount;
      state.settingsPage = "goal-confirm"; render(); return;
    }
    if (action === "settings-goal-confirm-save") {
      const amount = state.goalAmount;
      const code = state.goalCode || state.settings?.investment?.goal?.code || "RETIREMENT";
      try {
        await apiJSON("/api/goal", "PATCH", { financialGoal: code, targetAmount: amount });
        state.goalAmount = amount; state.settingsPage = "root"; await loadSettings(); toast("목표를 저장했어요");
      } catch (error) { toast(`목표를 저장하지 못했어요: ${error.message}`); }
      return;
    }
    if (action === "settings-interest-choice") {
      const code = target.dataset.value;
      state.selectedInterests = state.selectedInterests.includes(code) ? state.selectedInterests.filter(item => item !== code) : [...state.selectedInterests, code];
      render(); return;
    }
    if (action === "settings-interests-save") {
      if (state.selectedInterests.length < 1 || state.selectedInterests.length > 5) { toast("1개 이상 5개 이하로 선택해 주세요"); return; }
      try { await apiJSON("/api/me/settings/interests", "PATCH", { interests: state.selectedInterests }); state.settingsPage = "root"; await loadSettings(); toast("관심 정책을 저장했어요"); }
      catch (error) { toast(`관심 정책을 저장하지 못했어요: ${error.message}`); }
      return;
    }
    const pages = { "settings-accounts": "accounts", "settings-goal": "goal", "settings-interests": "interests", "settings-password": "password", "settings-logout": "logout", "settings-delete": "delete" };
    if (pages[action]) await openSettingsPage(pages[action]);
  }

  app.addEventListener("click", event => {
    const target = event.target.closest("[data-action]");
    if (!target) return;
    if (target.classList.contains("overlay") && event.target !== target) return;
    const action = target.dataset.action;
    if (["today", "newsroom", "asset"].includes(action)) {
      state.tab = action; state.detailTicker = null; state.overlay = null; render(); return;
    }
    if (action === "detail") { state.detailTicker = target.dataset.ticker; state.tab = "newsroom"; render(); return; }
    if (action === "back") { state.detailTicker = null; render(); return; }
    if (action === "close-overlay") { state.overlay = null; render(); return; }
    if (action.startsWith("settings-")) { handleSettingsAction(target); return; }
    if (["settings", "notifications", "connect", "login"].includes(action)) { state.overlay = action; if (action === "settings") { state.settingsPage = "root"; loadSettings(); } render(); return; }
    if (action === "refresh") refreshLive();
  });
  app.addEventListener("submit", async event => {
    if (event.target.id === "demo-login-form") {
      event.preventDefault();
      if (location.protocol === "file:") { state.loginError = "실시간 연결은 로컬 서버를 실행한 뒤 사용할 수 있어요."; render(); return; }
      const values = new FormData(event.target);
      try {
        const response = await fetch("/api/demo-login", { method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: values.get("email"), password: values.get("password") }) });
        const body = await response.json();
        if (!response.ok || !body.connected) throw new Error(body.message || "로그인에 실패했어요.");
        if (Number(body.userId) !== Number(data.user.userId)) {
          data.user = { userId: body.userId, userName: "사용자" };
          data.responses = {};
          data.cachedBrokerBalance = null;
          state.settings = null;
        }
        state.loginError = null;
        await refreshLive();
      } catch (error) { state.loginError = error.message; render(); }
      return;
    }
    if (event.target.id !== "settings-password-form") return;
    event.preventDefault();
    const values = new FormData(event.target);
    if (values.get("newPassword") !== values.get("confirmPassword")) { toast("새 비밀번호가 일치하지 않아요"); return; }
    toast("비밀번호 변경은 공유 데모에서 사용할 수 없어요");
  });
  app.addEventListener("input", event => {
    if (event.target.id !== "setting-goal-amount") return;
    state.goalAmount = Number(event.target.value);
    const label = document.getElementById("setting-goal-value");
    if (label) label.textContent = shortWon(state.goalAmount);
  });
  document.addEventListener("keydown", event => {
    if (event.key === "Escape") { state.overlay = null; state.detailTicker = null; render(); }
  });
  render();
  if (location.protocol !== "file:") fetch("/api/demo-status").then(response => response.json()).then(status => {
    if (status.connected) refreshLive();
  }).catch(() => {});
  setInterval(() => {
    const clock = document.querySelector(".status-bar strong");
    if (clock) clock.textContent = clockText();
  }, 30000);
})();
