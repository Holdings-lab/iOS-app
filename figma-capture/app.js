const statusBar = () => `<div class="status"><span>9:41</span><span class="dynamic-island"></span><span class="status-icons">▮▮▮ ᯤ ▰</span></div>`;
const tabs = (active) => `<nav class="tabbar"><div class="tab ${active==='today'?'active':''}"><i>⌂</i>오늘</div><div class="tab ${active==='news'?'active':''}"><i>▤</i>뉴스룸</div><div class="tab ${active==='assets'?'active':''}"><i>◫</i>보유자산</div></nav>`;
const frame = (group, state, body, cls='') => `<section class="capture-item"><div class="frame-label"><h2>${group}</h2><span class="state-chip">${state}</span></div><article class="phone ${cls}">${statusBar()}${body}</article></section>`;
const iconButton = (label) => `<span class="icon-button">${label}</span>`;

function login(state){
  const loading=state==='로딩'; const error=state==='오류'; const focused=state==='선택';
  return `<div class="screen-body pad24"><div class="brand-lockup"><p class="brand-mark">POLSIGNAL</p><h3>폴리시 파이낸스</h3><p>정책 변화가 내 투자에 미치는 영향을<br>가장 먼저 확인하세요.</p></div><div class="form">
    <div class="field ${focused?'focused':''} ${error?'error':''}">✉ <span>${focused?'investor@polsignal.kr':'이메일 주소'}</span></div>
    <div class="field ${error?'error':''}">● <span>${focused?'••••••••':'비밀번호'}</span><b style="margin-left:auto">⌁</b></div>
    ${error?'<div class="inline-error">이메일 또는 비밀번호를 다시 확인해 주세요.</div>':''}
    <div class="button ${(!focused&&!loading&&!error)?'disabled':''}">${loading?'<span class="spinner"></span> 로그인 중...':'로그인'}</div>
  </div><div class="divider">또는 간편 로그인</div><div class="socials"><div class="social"></div><div class="social">G</div><div class="social kakao">K</div></div><p class="signup">아직 계정이 없나요? <b>회원가입</b></p></div>`;
}

function onboarding(state){
  if(state==='로딩') return `<div class="screen-body pad24"><div class="topbar"><b>맞춤 설정</b><span>8 / 8</span></div><div class="progress"><i style="width:100%"></i></div><div class="center-loader"><div><div class="loader-ring"></div><b>맞춤 리포트를 준비 중이에요</b><span>선택한 관심사와 자산을 분석하고 있습니다.</span></div></div></div>`;
  const selected=state==='선택'; const error=state==='오류';
  return `<div class="screen-body pad24"><div class="topbar"><b>맞춤 설정</b><span style="font-size:12px;color:var(--ink3)">1 / 8</span></div><div class="progress"><i></i></div><div class="onboard-head"><small>STEP 1</small><h3>왜 투자하시나요?</h3><p>목표에 맞춰 꼭 필요한 변화만 알려드릴게요.</p></div>
  ${error?'<div class="compact-banner"><b>선택 내용을 저장하지 못했어요.</b><span>다시 시도</span></div>':''}
  <div class="option-list">
    <div class="option ${selected?'selected':''}"><span class="option-icon">⌂</span><span class="option-copy"><b>내 집 마련</b><span>주거 자금을 차근차근 모아요</span></span><span class="check">${selected?'✓':''}</span></div>
    <div class="option"><span class="option-icon">↗</span><span class="option-copy"><b>자산 성장</b><span>장기적인 수익을 만들고 싶어요</span></span><span class="check"></span></div>
    <div class="option"><span class="option-icon">♨</span><span class="option-copy"><b>은퇴 준비</b><span>미래의 안정적인 현금 흐름</span></span><span class="check"></span></div>
    <div class="option"><span class="option-icon">◎</span><span class="option-copy"><b>투자 공부</b><span>시장과 정책을 이해하고 싶어요</span></span><span class="check"></span></div>
  </div><div class="bottom-action"><div class="button ${selected?'':'disabled'}">다음</div></div></div>`;
}

const holdings = `<div class="holding"><span class="ticker">삼전</span><span class="holding-copy"><b>삼성전자</b><span>005930 · 24주</span></span><span class="value">₩1,884,000<em>+2.31%</em></span></div><div class="holding"><span class="ticker">NVDA</span><span class="holding-copy"><b>NVIDIA</b><span>NVDA · 6주</span></span><span class="value">₩1,426,200<em>+1.08%</em></span></div><div class="holding"><span class="ticker">TSLA</span><span class="holding-copy"><b>Tesla</b><span>TSLA · 3주</span></span><span class="value">₩892,500<em class="down">-0.74%</em></span></div>`;

function today(state){
  let content='';
  if(state==='로딩') content=`<div class="sk-card"></div><div class="sk-card" style="height:210px"></div><div class="sk-card" style="height:95px"></div>`;
  else if(state==='데이터 없음') content=`<div class="card briefing"><span class="pill">오늘의 브리핑</span><h4>연결된 자산이 아직 없어요</h4><p>보유 종목을 연결하면 정책 변화가 내 자산에 미치는 영향을 보여드려요.</p></div><div class="card empty"><div class="empty-icon">＋</div><h4>증권 계좌를 연결해 주세요</h4><p>흩어진 자산을 모아 한 번에 확인할 수 있어요.</p><div class="button">계좌 연결하기</div></div>`;
  else { const alert=state==='선택'; content=`${alert?'<div class="compact-banner"><b>관심 정책 알림 2건이 도착했어요.</b><span>모두 보기</span></div>':''}<div class="card briefing"><div class="card-head"><b>오늘의 브리핑</b><span>7월 19일</span></div><span class="pill">차분히 지켜봐요</span><h4>반도체 지원책이<br>보유 종목에 긍정적이에요</h4><p>삼성전자와 NVIDIA 관련 정책 신호가 개선됐습니다.</p></div><div class="card"><div class="card-head"><b>내 보유자산 TOP 3</b><span>전체 보기</span></div>${holdings}</div><div class="card"><div class="card-head"><b>투자 목표</b><span>68%</span></div><div class="goal-line"><span>내 집 마련</span><b>₩34,200,000 / ₩50,000,000</b></div><div class="bar"><i></i></div></div><div class="card"><div class="news-row"><span class="news-thumb">POL</span><span class="news-copy"><b>정부, 첨단산업 투자 세액공제 확대</b><span>정책브리핑 · 18분 전</span></span></div></div>`; }
  return `<div class="screen-body"><div class="topbar"><div class="topbar-title"><small>2026년 7월 19일 일요일</small><h3>오늘</h3></div><div class="actions">${iconButton('♢')}${iconButton('⚙')}</div></div>${content}</div>${tabs('today')}`;
}

function assets(state){
  const empty=state==='데이터 없음'; const sheet=state==='선택'; const failed=state==='오류';
  const body=empty?`<div class="card empty" style="margin-top:60px"><div class="empty-icon">◫</div><h4>아직 연결된 자산이 없어요</h4><p>증권 계좌를 연결하면 총 자산과 수익률을 자동으로 계산해 드려요.</p><div class="button">첫 계좌 연결하기</div></div>`:`<div class="hero"><small>총 평가금액</small><h3>₩42,856,700</h3><p>총 수익 <b>+₩2,846,200 (+7.12%)</b></p><div class="composition"><i></i><i></i><i></i></div><div class="legend-row"><span>● 국내주식 48%</span><span>● 해외주식 31%</span><span>● 현금 21%</span></div></div><div class="section-title"><b>보유 종목</b><span>총 7종목</span></div><div class="card">${holdings}</div><div class="section-title"><b>수익 요약</b><span>이번 달</span></div><div class="summary-grid"><div class="mini"><span>실현 손익</span><b class="up">+₩182,500</b></div><div class="mini"><span>배당금</span><b>₩64,200</b></div></div>`;
  return `<div class="screen-body"><div class="topbar"><div class="topbar-title"><small>포트폴리오</small><h3>내 자산</h3></div>${iconButton('＋')}</div>${body}</div>${tabs('assets')}${sheet||failed?`<div class="scrim"></div><div class="sheet"><div class="grab"></div><h3>${failed?'계좌 연결에 실패했어요':'증권사 연결'}</h3><p>${failed?'잠시 후 다시 시도하거나 다른 증권사를 선택해 주세요.':'자산을 불러올 증권사를 선택해 주세요.'}</p>${failed?'<div class="inline-error" style="margin-bottom:14px">인증 시간이 만료되었습니다. 다시 로그인해 주세요.</div>':''}<div class="broker selected"><span class="broker-logo">M</span><b>미래에셋증권</b><span>${failed?'다시 연결':'선택됨 ✓'}</span></div><div class="broker"><span class="broker-logo">K</span><b>키움증권</b><span>연결</span></div><div class="broker"><span class="broker-logo">S</span><b>삼성증권</b><span>연결</span></div><div class="button" style="margin-top:18px">${failed?'다시 시도':'계속'}</div></div>`:''}`;
}

function newsroom(state){
  let content='';
  if(state==='로딩') content=`<div class="sk-line short"></div><div class="sk-line med"></div><div class="sk-card" style="height:190px"></div><div class="sk-card" style="height:160px"></div>`;
  else if(state==='데이터 없음') content=`<div class="card empty" style="margin-top:68px"><div class="empty-icon">▤</div><h4>맞춤 뉴스가 아직 없어요</h4><p>보유 종목을 연결하면 내 자산과 관련된 정책 뉴스를 골라드려요.</p><div class="button">보유자산 연결하기</div></div>`;
  else if(state==='오류') content=`<div class="card empty error-card" style="margin-top:68px"><div class="empty-icon">!</div><h4>뉴스를 불러오지 못했어요</h4><p>네트워크 연결을 확인한 뒤 다시 시도해 주세요.</p><div class="button">다시 시도</div></div>`;
  else { const chosen=state==='선택'; content=`<div class="signal ${chosen?'watch':''}"><span>${chosen?'◉':'✓'}</span><b>${chosen?'NVIDIA 정책 신호를 자세히 보는 중':'오늘은 차분히 지켜봐도 좋아요'}</b></div><div class="card digest-card"><div class="digest-top"><small>MY DAILY DIGEST</small><h4>반도체 · AI 정책 브리핑</h4></div><div class="digest-body"><p>미국과 한국의 첨단산업 지원 정책이 보유 종목에 우호적으로 작용하고 있어요.</p><div class="tag-row"><span class="tag">삼성전자</span><span class="tag">NVIDIA</span><span class="tag">정책 수혜</span></div></div></div><div class="card"><div class="card-head"><b>종목별 핵심 변화</b><span>3개</span></div>${holdings}</div><div class="card"><div class="news-row"><span class="news-thumb">AI</span><span class="news-copy"><b>AI 인프라 투자 확대안, 국회 상임위 통과</b><span>매일경제 · 32분 전</span></span></div></div>`; }
  return `<div class="screen-body"><div class="topbar"><div class="topbar-title"><small>나를 위한 정책 뉴스</small><h3>뉴스룸</h3></div>${iconButton('⌕')}</div><div class="digest-head"><span class="date">7월 19일 일요일</span><p>보유 종목에 중요한 변화만 모았어요.</p></div>${content}</div>${tabs('news')}`;
}

function detail(state){
  const fallback=state==='오류'; const expanded=state==='확장';
  return `<div class="screen-body"><div class="topbar"><div class="actions">${iconButton('‹')}</div><b>뉴스 상세</b>${iconButton('↗')}</div><div class="article-header"><span class="meta">정책 · 반도체</span><h3>첨단산업 세액공제 확대,<br>삼성전자 투자 여력 커진다</h3><p>정책브리핑 · 2026.07.19 09:12</p></div><div class="article-image ${fallback?'fallback':''}">${fallback?'이미지를 불러올 수 없음':'POLICY SIGNAL'}</div><div class="ai-box"><small>AI 판단</small><h4>보유 종목에 긍정적인 변화예요</h4><p>설비 투자 비용 부담이 줄어 삼성전자의 중장기 현금 흐름 개선 가능성이 있습니다.</p></div><div class="section-title"><b>${expanded?'새로 확인된 사실 4가지':'핵심 요약'}</b><span>${expanded?'접기':'펼치기'}</span></div><ul class="bullet-list"><li>반도체 국가전략기술 공제율이 상향됩니다.</li><li>2027년까지 국내 설비투자에 우선 적용됩니다.</li>${expanded?'<li>대기업 공제 한도가 기존 대비 5%p 확대됩니다.</li><li>세부 시행령은 다음 달 공개될 예정입니다.</li>':''}</ul><div class="section-title"><b>출처</b><span>원문 확인</span></div><div class="source-row ${fallback?'disabled':''}"><span>↗</span><b>정책브리핑 원문</b><i style="margin-left:auto">›</i></div></div>`;
}

function settings(state){
  const loading=state==='로딩'; const error=state==='오류'; const selected=state==='선택';
  return `<div class="screen-body"><div class="topbar"><div class="topbar-title"><small>계정 및 앱 관리</small><h3>설정</h3></div>${iconButton('×')}</div>${error?'<div class="compact-banner"><b>연결된 계정 1개의 인증이 만료됐어요.</b><span>확인</span></div>':''}<div class="card profile"><span class="avatar">김</span><span class="profile-copy"><b>김폴시그널</b><span>investor@polsignal.kr</span></span><span class="chevron">›</span></div><section class="settings-section"><h4>알림</h4><div class="settings-group"><div class="setting-row"><span class="setting-icon">♢</span><span>정책 변화 알림</span><span class="toggle on"><i></i></span></div><div class="setting-row"><span class="setting-icon">☼</span><span>오늘 브리핑 시간</span><span class="segment"><span>08:00</span><span class="active">09:00</span><span>10:00</span></span></div><div class="setting-row"><span class="setting-icon">↗</span><span>테스트 알림 보내기</span><span class="chevron">${loading?'전송 중…':'›'}</span></div></div></section><section class="settings-section"><h4>투자 설정</h4><div class="settings-group"><div class="setting-row"><span class="setting-icon">◎</span><span>투자 목표</span><span class="chevron">내 집 마련 ›</span></div><div class="setting-row"><span class="setting-icon">◫</span><span>연결 계좌</span><span class="chevron">${error?'주의 필요':'2개 ›'}</span></div><div class="setting-row"><span class="setting-icon">▤</span><span>관심 정책</span><span class="chevron">5개 ›</span></div></div></section><section class="settings-section"><h4>계정</h4><div class="settings-group"><div class="setting-row"><span class="setting-icon">⌘</span><span>비밀번호 변경</span><span class="chevron">›</span></div><div class="setting-row"><span class="setting-icon">↪</span><span>로그아웃</span><span class="chevron">›</span></div></div></section></div>${loading?'<div class="toast"><span class="spinner"></span><b>테스트 알림을 보내고 있어요.</b></div>':''}${selected?'<div class="scrim"></div><div class="modal"><div class="modal-icon">↪</div><h3>로그아웃할까요?</h3><p>언제든 다시 로그인하면<br>내 자산과 설정을 이어서 볼 수 있어요.</p><div class="modal-actions"><div class="button secondary">취소</div><div class="button danger">로그아웃</div></div></div>':''}`;
}

const screens = [
  ['로그인','기본',login('기본'),'login'],['로그인','로딩',login('로딩'),'login'],['로그인','오류',login('오류'),'login'],['로그인','선택',login('선택'),'login'],
  ['온보딩','기본',onboarding('기본'),'onboarding'],['온보딩','선택',onboarding('선택'),'onboarding'],['온보딩','로딩',onboarding('로딩'),'onboarding'],['온보딩','오류',onboarding('오류'),'onboarding'],
  ['오늘 탭','기본',today('기본'),''],['오늘 탭','로딩',today('로딩'),''],['오늘 탭','데이터 없음',today('데이터 없음'),''],['오늘 탭','선택',today('선택'),''],
  ['보유자산','기본',assets('기본'),'assets'],['보유자산','데이터 없음',assets('데이터 없음'),'assets'],['보유자산','선택',assets('선택'),'assets'],['보유자산','오류',assets('오류'),'assets'],
  ['뉴스룸','기본',newsroom('기본'),''],['뉴스룸','로딩',newsroom('로딩'),''],['뉴스룸','데이터 없음',newsroom('데이터 없음'),''],['뉴스룸','오류',newsroom('오류'),''],['뉴스룸','선택',newsroom('선택'),''],
  ['뉴스 상세','기본',detail('기본'),''],['뉴스 상세','오류',detail('오류'),''],['뉴스 상세','확장',detail('확장'),''],
  ['설정','기본',settings('기본'),''],['설정','로딩',settings('로딩'),''],['설정','오류',settings('오류'),''],['설정','선택',settings('선택'),'']
];

document.querySelector('#board').innerHTML = screens.map(([g,s,b,c]) => frame(g,s,b,c)).join('');
