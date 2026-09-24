(() => {
  "use strict";

  const app = document.getElementById("app");
  const data = window.__EGUN_SNAPSHOT__;
  if (!data || data.source !== "simulator-session") {
    app.textContent = "현재 시뮬레이터 사용자의 데모 데이터를 찾지 못했습니다.";
    return;
  }
  const state = { tab: "today", detailTicker: null, overlay: null, liveToday: false, liveError: null };
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
      ${state.liveError ? `<div class="fallback-banner">${icon("alert")}<span>${escapeHTML(state.liveError)}</span></div>` : ""}
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

  function renderOverlay() {
    if (!state.overlay) return "";
    if (state.overlay === "connect") return `<div class="overlay" data-action="close-overlay"><div class="sheet" role="dialog" aria-modal="true" aria-label="계좌 연결"><div class="sheet-handle"></div><div class="sheet-head"><h2>계좌 연결</h2><button data-action="close-overlay" aria-label="닫기">${icon("close")}</button></div><p>한국투자증권 모의투자 계좌를 연결해 자산을 확인할 수 있어요.</p><div class="sheet-account"><strong>한국투자증권</strong><span>${data.cachedBrokerBalance ? "읽기 전용 계좌 연결됨" : "연결 전"}</span></div><button class="primary-button" data-action="close-overlay">확인</button></div></div>`;
    if (state.overlay === "notifications") return `<div class="overlay" data-action="close-overlay"><div class="sheet full-sheet" role="dialog" aria-modal="true" aria-label="알림"><div class="sheet-head"><h2>알림</h2><button data-action="close-overlay" aria-label="닫기">${icon("close")}</button></div><div class="centered-state"><h2>새로운 알림이 없어요</h2><p>새로운 분석이 도착하면 이곳에 알려드릴게요.</p></div></div></div>`;
    if (state.overlay === "settings") return `<div class="overlay" data-action="close-overlay"><div class="sheet full-sheet" role="dialog" aria-modal="true" aria-label="설정"><div class="sheet-head"><h2>설정</h2><button data-action="close-overlay" aria-label="닫기">${icon("close")}</button></div><div class="settings-profile"><span class="profile-avatar">${escapeHTML(data.user?.userName?.[0] || "투")}</span><div><strong>${escapeHTML(data.user?.userName || "투자자")}</strong><small>내 투자 현황을 확인해 보세요</small></div></div><button class="settings-row" data-action="refresh">${icon("refresh")} 실시간 데이터 새로고침 ${icon("chevron")}</button><button class="settings-row" data-action="asset">${icon("pie")} 내 자산 보기 ${icon("chevron")}</button></div></div>`;
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
    if (["settings", "notifications", "connect"].includes(action)) { state.overlay = action; render(); return; }
    if (action === "refresh") refreshLive();
  });
  document.addEventListener("keydown", event => {
    if (event.key === "Escape") { state.overlay = null; state.detailTicker = null; render(); }
  });
  render();
  setInterval(() => {
    const clock = document.querySelector(".status-bar strong");
    if (clock) clock.textContent = clockText();
  }, 30000);
})();
