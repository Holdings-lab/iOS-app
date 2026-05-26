import SwiftUI

struct SignalView: View {
    @Binding private var externalRoute: PolSignalRoute?
    @State private var snapshot: SignalSectorDetailSnapshot

    init(
        initialRoute: PolSignalRoute? = nil,
        externalRoute: Binding<PolSignalRoute?> = .constant(nil),
        viewModel: PolSignalFlowViewModel? = nil
    ) {
        _externalRoute = externalRoute
        _snapshot = State(initialValue: SignalSectorDetailSnapshot.fixture(for: initialRoute))
        _ = viewModel
    }

    var body: some View {
        SignalSectorDetailView(snapshot: snapshot)
            .onChange(of: externalRoute) { _, route in
                guard let route else { return }
                snapshot = SignalSectorDetailSnapshot.fixture(for: route)
                externalRoute = nil
            }
    }
}

// MARK: - Detail View

struct SignalSectorDetailView: View {
    let snapshot: SignalSectorDetailSnapshot
    var state: SignalSectorDetailLoadState = .loaded

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForecastCard(snapshot: snapshot)

                    switch state {
                    case .loaded:
                        signalSection
                        TimelineCard(points: snapshot.timeline)

                        if snapshot.checkpoints.isEmpty == false {
                            checkpointSection
                        }
                    case .loading:
                        SignalSkeletonStack()
                    case .error(let message):
                        SignalErrorMessage(message: message)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .background(SignalDetailToken.bgScreen.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(SignalDetailToken.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Text(snapshot.sector.displayName)
                .font(.pretendard(22, weight: .bold, relativeTo: .title2))
                .foregroundStyle(SignalDetailToken.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("이번 주 기준")
                .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(SignalDetailToken.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(SignalDetailToken.bgSubtle, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(SignalDetailToken.rule, lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(SignalDetailToken.bgScreen)
    }

    private var signalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SignalDetailSectionTitle("이번 주 눈에 띄는 신호")

            LazyVStack(spacing: 8) {
                let cards = snapshot.visibleSignalCards

                if cards.isEmpty {
                    EmptyIntensityCard(sectorName: snapshot.sector.displayName)
                } else {
                    ForEach(cards) { card in
                        IntensityCard(card: card)
                    }
                }
            }
        }
    }

    private var checkpointSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SignalDetailSectionTitle("다음에 볼 이벤트")
            CheckpointCard(events: Array(snapshot.checkpoints.prefix(2)))
        }
    }
}

// MARK: - Data

enum SignalSectorDetailLoadState {
    case loaded
    case loading
    case error(String)
}

struct SignalSectorDetailSnapshot: Identifiable {
    let id = UUID()
    let sector: PortfolioThemeSignal.Theme
    let judgment: SignalDetailJudgment
    let forecastReturnPercent: Double
    let currentPrice: String?
    let expectedPrice: String?
    let priceDelta: String?
    let signalCards: [SignalCard]
    let timeline: [SignalTimelinePoint?]
    let checkpoints: [SignalCheckpointEvent]

    var visibleSignalCards: [SignalCard] {
        Array(
            signalCards
                .filter { $0.shouldDisplay }
                .sorted { lhs, rhs in
                    if lhs.intensity.sortPriority == rhs.intensity.sortPriority {
                        return lhs.title < rhs.title
                    }
                    return lhs.intensity.sortPriority > rhs.intensity.sortPriority
                }
                .prefix(3)
        )
    }

    var direction: SignalForecastDirection {
        SignalForecastDirection(value: forecastReturnPercent)
    }

    static func fixture(for route: PolSignalRoute?) -> SignalSectorDetailSnapshot {
        guard case .detail(let id) = route else {
            return .main
        }
        return fixture(forEventId: id)
    }

    static func fixture(forEventId id: Int) -> SignalSectorDetailSnapshot {
        // TODO: wire to real VM and map sector ID from backend payload.
        switch id {
        case 102:
            return .strongWarning
        case 103:
            return .noEvent
        case 104:
            return .calm
        case 105:
            return .newUser
        default:
            return .main
        }
    }
}

enum SignalDetailJudgment {
    case caution
    case action
    case watch

    var label: String {
        switch self {
        case .caution:
            return "조심하세요"
        case .action:
            return "대응하세요"
        case .watch:
            return "지켜봐요"
        }
    }

    var foreground: Color {
        switch self {
        case .caution:
            return SignalDetailToken.badgeWarnFg
        case .action:
            return SignalDetailToken.badgeActFg
        case .watch:
            return SignalDetailToken.badgeWatchFg
        }
    }

    var background: Color {
        switch self {
        case .caution:
            return SignalDetailToken.badgeWarnBg
        case .action:
            return SignalDetailToken.badgeActBg
        case .watch:
            return SignalDetailToken.badgeWatchBg
        }
    }
}

struct SignalTimelinePoint: Identifiable {
    let id = UUID()
    let weekLabel: String
    let returnPercent: Double
    let judgment: SignalDetailJudgment

    var direction: SignalForecastDirection {
        SignalForecastDirection(value: returnPercent)
    }
}

struct SignalCheckpointEvent: Identifiable {
    let id = UUID()
    let dateText: String
    let title: String
    let description: String
}

enum SignalForecastDirection {
    case up
    case down
    case flat

    init(value: Double) {
        if abs(value) < 0.1 {
            self = .flat
        } else if value > 0 {
            self = .up
        } else {
            self = .down
        }
    }

    var symbol: String {
        switch self {
        case .up:
            return "▲"
        case .down:
            return "▼"
        case .flat:
            return "●"
        }
    }

    var color: Color {
        switch self {
        case .up:
            return SignalDetailToken.directionUp
        case .down:
            return SignalDetailToken.directionDown
        case .flat:
            return SignalDetailToken.directionFlat
        }
    }

    var label: String {
        switch self {
        case .up:
            return "상승 예상"
        case .down:
            return "하락 예상"
        case .flat:
            return "횡보 예상"
        }
    }
}

// MARK: - Forecast

private struct ForecastCard: View {
    let snapshot: SignalSectorDetailSnapshot

    var body: some View {
        SignalDetailCard(padding: 24) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    sectorIcon

                    Text(snapshot.sector.displayName)
                        .font(.pretendard(22, weight: .bold, relativeTo: .title2))
                        .foregroundStyle(SignalDetailToken.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    SignalJudgmentPill(judgment: snapshot.judgment)
                }

                Divider()
                    .overlay(SignalDetailToken.rule)
                    .padding(.vertical, 16)

                Text("5거래일 후")
                    .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(SignalDetailToken.textTertiary)
                    .monospacedDigit()

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(snapshot.direction.symbol)
                        .font(.pretendard(22, weight: .bold, relativeTo: .title2))
                    Text(snapshot.forecastReturnText)
                        .font(.pretendard(34, weight: .bold, relativeTo: .largeTitle))
                        .monospacedDigit()
                }
                .foregroundStyle(snapshot.direction.color)
                .padding(.top, 6)

                Text(snapshot.direction.label)
                    .font(.pretendard(15, weight: .medium, relativeTo: .body))
                    .foregroundStyle(SignalDetailToken.textSecondary)
                    .padding(.top, 8)

                if snapshot.hasPriceBox {
                    priceBox
                        .padding(.top, 12)
                }
            }
        }
    }

    private var sectorIcon: some View {
        Image(systemName: snapshot.sector.sfSymbol)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(snapshot.sector.detailForeground)
            .frame(width: 40, height: 40)
            .background(snapshot.sector.detailBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private var priceBox: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("예상 가격")
                .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(SignalDetailToken.textTertiary)

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(snapshot.currentPrice ?? "") → \(snapshot.expectedPrice ?? "")")
                    .foregroundStyle(SignalDetailToken.textPrimary)

                Text("(\(snapshot.priceDelta ?? ""))")
                    .foregroundStyle(snapshot.direction.color)
            }
            .font(.pretendard(14, weight: .semibold, relativeTo: .footnote))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(SignalDetailToken.bgSubtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Intensity

private struct IntensityCard: View {
    let card: SignalCard

    var body: some View {
        SignalDetailCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(card.intensity.dotColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 7)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(card.title)
                                .font(.pretendard(16, weight: .semibold, relativeTo: .subheadline))
                                .foregroundStyle(SignalDetailToken.textPrimary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            Text(card.intensity.label)
                                .font(.pretendard(11, weight: .medium, relativeTo: .caption2))
                                .foregroundStyle(card.intensity.labelColor)
                                .lineLimit(1)
                                .fixedSize()
                        }

                        Text(card.description)
                            .font(.pretendard(14, weight: .regular, relativeTo: .footnote))
                            .foregroundStyle(SignalDetailToken.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let newsTitle = card.newsTitle {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                            .overlay(SignalDetailToken.rule)

                        HStack(spacing: 8) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(SignalDetailToken.textTertiary)
                                .frame(width: 14, height: 14)

                            Text(newsTitle)
                                .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                                .foregroundStyle(SignalDetailToken.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.leading, 20)
                    }
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let news = card.newsTitle.map { ", 관련 뉴스 \($0)" } ?? ""
        return "\(card.intensity.label) 강도 신호, \(card.title), \(card.description)\(news)"
    }
}

private struct EmptyIntensityCard: View {
    let sectorName: String

    var body: some View {
        SignalDetailCard(padding: 0) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(SignalDetailToken.textTertiary)
                    .frame(width: 20, height: 20)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text("이번 주는 조용한 한 주예요")
                        .font(.pretendard(16, weight: .semibold, relativeTo: .subheadline))
                        .foregroundStyle(SignalDetailToken.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(sectorName) 관련 특이 신호가 감지되지 않았어요.")
                        .font(.pretendard(14, weight: .regular, relativeTo: .footnote))
                        .foregroundStyle(SignalDetailToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Timeline

private struct TimelineCard: View {
    let points: [SignalTimelinePoint?]

    private var normalizedPoints: [SignalTimelinePoint?] {
        (0..<4).map { index in
            points.indices.contains(index) ? points[index] : nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SignalDetailSectionTitle("최근 4주 신호 흐름")

            SignalDetailCard(padding: 20) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(normalizedPoints.enumerated()), id: \.offset) { index, point in
                        TimelineColumn(point: point, isCurrentWeek: index == 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
        }
    }
}

private struct TimelineColumn: View {
    let point: SignalTimelinePoint?
    let isCurrentWeek: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(point?.weekLabel ?? placeholderWeekLabel)
                .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(SignalDetailToken.textTertiary)
                .lineLimit(1)

            ZStack {
                if let point {
                    Circle()
                        .fill(point.judgment.foreground)
                        .frame(width: isCurrentWeek ? 16 : 12, height: isCurrentWeek ? 16 : 12)
                        .overlay {
                            if isCurrentWeek {
                                Circle()
                                    .stroke(SignalDetailToken.textPrimary, lineWidth: 2)
                            }
                        }
                } else {
                    Circle()
                        .fill(SignalDetailToken.rule)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(height: 20)

            Text(point?.returnText ?? "—")
                .font(.pretendard(15, weight: .semibold, relativeTo: .body))
                .foregroundStyle(point?.direction.color ?? SignalDetailToken.textTertiary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            if let point {
                Text(point.judgment.label)
                    .font(.pretendard(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(point.judgment.foreground)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(point.judgment.background, in: Capsule(style: .continuous))
            } else {
                Text("—")
                    .font(.pretendard(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(SignalDetailToken.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var placeholderWeekLabel: String {
        isCurrentWeek ? "이번 주" : "—"
    }
}

// MARK: - Checkpoints

private struct CheckpointCard: View {
    let events: [SignalCheckpointEvent]

    var body: some View {
        SignalDetailCard(padding: 20) {
            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    CheckpointRow(event: event)

                    if index < events.count - 1 {
                        Divider()
                            .overlay(SignalDetailToken.rule)
                            .padding(.vertical, 16)
                    }
                }
            }
        }
    }
}

private struct CheckpointRow: View {
    let event: SignalCheckpointEvent

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(SignalDetailToken.textTertiary)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.dateText)
                    .font(.pretendard(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(SignalDetailToken.textTertiary)
                    .monospacedDigit()

                Text(event.title)
                    .font(.pretendard(16, weight: .semibold, relativeTo: .subheadline))
                    .foregroundStyle(SignalDetailToken.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.description)
                    .font(.pretendard(14, weight: .regular, relativeTo: .footnote))
                    .foregroundStyle(SignalDetailToken.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Support Views

private struct SignalDetailCard<Content: View>: View {
    let padding: CGFloat
    let content: Content

    init(padding: CGFloat, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SignalDetailToken.bgCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

private struct SignalDetailSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.pretendard(18, weight: .bold, relativeTo: .headline))
            .foregroundStyle(SignalDetailToken.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }
}

private struct SignalJudgmentPill: View {
    let judgment: SignalDetailJudgment

    var body: some View {
        Text(judgment.label)
            .font(.pretendard(12, weight: .semibold, relativeTo: .caption))
            .foregroundStyle(judgment.foreground)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(judgment.background, in: Capsule(style: .continuous))
    }
}

private struct SignalSkeletonStack: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                SignalDetailCard(padding: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SignalDetailToken.rule)
                            .frame(width: 160, height: 18)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SignalDetailToken.rule)
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SignalDetailToken.rule)
                            .frame(width: 220, height: 14)
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

private struct SignalErrorMessage: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.pretendard(14, weight: .regular, relativeTo: .footnote))
            .foregroundStyle(SignalDetailToken.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .accessibilityLabel(message)
    }
}

// MARK: - Tokens

private enum SignalDetailToken {
    static let bgScreen = Color(hex: "F5F6F8")
    static let bgCard = Color(hex: "FFFFFF")
    static let bgSubtle = Color(hex: "FAFBFC")
    static let textPrimary = Color(hex: "1A1D29")
    static let textSecondary = Color(hex: "5A6072")
    static let textTertiary = Color(hex: "9DA3B4")
    static let directionDown = Color(hex: "E84A4A")
    static let directionUp = Color(hex: "16A571")
    static let directionFlat = Color(hex: "9DA3B4")
    static let badgeWarnBg = Color(hex: "FFF4D6")
    static let badgeWarnFg = Color(hex: "C68A00")
    static let badgeActBg = Color(hex: "FDE2E4")
    static let badgeActFg = Color(hex: "C0392B")
    static let badgeWatchBg = Color(hex: "E3EDFD")
    static let badgeWatchFg = Color(hex: "2E5BBA")
    static let intensityHigh = Color(hex: "E84A4A")
    static let intensityMid = Color(hex: "F39C12")
    static let intensityLow = Color(hex: "F4C842")
    static let sectorTechBg = Color(hex: "E8EDFB")
    static let sectorTechFg = Color(hex: "4A6FE8")
    static let sectorFinanceBg = Color(hex: "FDF0DC")
    static let sectorFinanceFg = Color(hex: "F39C12")
    static let sectorGreenBg = Color(hex: "DCF5E8")
    static let sectorGreenFg = Color(hex: "16A571")
    static let rule = Color(hex: "EDEFF3")
}

// MARK: - Mapping

private extension SignalCard {
    var shouldDisplay: Bool {
        true
    }
}

private extension SignalCard.Intensity {
    var label: String {
        switch self {
        case .veryHigh:
            return "매우 높음"
        case .high:
            return "높음"
        case .medium:
            return "보통"
        }
    }

    var sortPriority: Int {
        switch self {
        case .veryHigh:
            return 3
        case .high:
            return 2
        case .medium:
            return 1
        }
    }

    var dotColor: Color {
        switch self {
        case .veryHigh:
            return SignalDetailToken.intensityHigh
        case .high:
            return SignalDetailToken.intensityMid
        case .medium:
            return SignalDetailToken.intensityLow
        }
    }

    var labelColor: Color {
        switch self {
        case .veryHigh:
            return SignalDetailToken.intensityHigh
        case .high:
            return SignalDetailToken.intensityMid
        case .medium:
            return SignalDetailToken.badgeWarnFg
        }
    }
}

private extension PortfolioThemeSignal.Theme {
    var detailBackground: Color {
        switch self {
        case .bigTech, .semiconductor:
            return SignalDetailToken.sectorTechBg
        case .financials:
            return SignalDetailToken.sectorFinanceBg
        case .greenEnergy:
            return SignalDetailToken.sectorGreenBg
        }
    }

    var detailForeground: Color {
        switch self {
        case .bigTech, .semiconductor:
            return SignalDetailToken.sectorTechFg
        case .financials:
            return SignalDetailToken.sectorFinanceFg
        case .greenEnergy:
            return SignalDetailToken.sectorGreenFg
        }
    }
}

private extension SignalSectorDetailSnapshot {
    var forecastReturnText: String {
        switch direction {
        case .up:
            return String(format: "+%.1f%%", forecastReturnPercent)
        case .down:
            return String(format: "%.1f%%", forecastReturnPercent)
        case .flat:
            return "0.0%"
        }
    }

    var hasPriceBox: Bool {
        currentPrice != nil && expectedPrice != nil && priceDelta != nil
    }
}

private extension SignalTimelinePoint {
    var returnText: String {
        switch direction {
        case .up:
            return String(format: "+%.1f%%", returnPercent)
        case .down:
            return String(format: "%.1f%%", returnPercent)
        case .flat:
            return "0.0%"
        }
    }
}

// MARK: - Fixtures

extension SignalSectorDetailSnapshot {
    static let main = SignalSectorDetailSnapshot(
        sector: .bigTech,
        judgment: .caution,
        forecastReturnPercent: -0.8,
        currentPrice: "$456.20",
        expectedPrice: "$452.30",
        priceDelta: "-3.90",
        signalCards: [
            SignalCard(
                id: UUID(),
                intensity: .veryHigh,
                title: "금리 결정이 빅테크 방향을 가를 수 있어요",
                description: "이번 주 FOMC 금리 발표가 예정돼 있어요.",
                newsTitle: "Fed, 금리 결정 앞두고 불확실성 고조"
            ),
            SignalCard(
                id: UUID(),
                intensity: .high,
                title: "부정적 뉴스가 평소보다 빠르게 쌓이고 있어요",
                description: "최근 5일간 빅테크 관련 부정 뉴스가 평소의 2배예요.",
                newsTitle: "관세 리스크에 애플·엔비디아 동반 하락"
            ),
            SignalCard(
                id: UUID(),
                intensity: .medium,
                title: "시장은 버티는데 뉴스는 흔들리고 있어요",
                description: "가격 흐름과 뉴스 분위기가 반대 방향이에요. 방향이 정해지면 빠르게 움직일 수 있어요.",
                newsTitle: "MS·알파벳 실적 앞두고 성장주 변동성 확대"
            )
        ],
        timeline: [
            SignalTimelinePoint(weekLabel: "3주 전", returnPercent: 0.2, judgment: .watch),
            SignalTimelinePoint(weekLabel: "2주 전", returnPercent: -0.1, judgment: .watch),
            SignalTimelinePoint(weekLabel: "지난 주", returnPercent: -0.4, judgment: .caution),
            SignalTimelinePoint(weekLabel: "이번 주", returnPercent: -0.8, judgment: .caution)
        ],
        checkpoints: [
            SignalCheckpointEvent(
                dateText: "5/28 (수)",
                title: "FOMC 금리 결정",
                description: "금리 경로 표현이 빅테크 밸류에이션에 영향을 줄 수 있어요."
            )
        ]
    )

    static let calm = SignalSectorDetailSnapshot(
        sector: .greenEnergy,
        judgment: .watch,
        forecastReturnPercent: 0.1,
        currentPrice: "$28.40",
        expectedPrice: "$28.43",
        priceDelta: "+0.03",
        signalCards: [],
        timeline: [
            SignalTimelinePoint(weekLabel: "3주 전", returnPercent: 0.0, judgment: .watch),
            SignalTimelinePoint(weekLabel: "2주 전", returnPercent: 0.1, judgment: .watch),
            SignalTimelinePoint(weekLabel: "지난 주", returnPercent: 0.0, judgment: .watch),
            SignalTimelinePoint(weekLabel: "이번 주", returnPercent: 0.1, judgment: .watch)
        ],
        checkpoints: [
            SignalCheckpointEvent(
                dateText: "6/2 (화)",
                title: "IEA 에너지 보고",
                description: "재생에너지 수요 전망이 친환경 테마 흐름을 바꿀 수 있어요."
            )
        ]
    )

    static let strongWarning = SignalSectorDetailSnapshot(
        sector: .semiconductor,
        judgment: .action,
        forecastReturnPercent: -2.1,
        currentPrice: "$238.60",
        expectedPrice: "$233.59",
        priceDelta: "-5.01",
        signalCards: [
            SignalCard(
                id: UUID(),
                intensity: .veryHigh,
                title: "보조금 발표 결과에 따라 반도체가 크게 움직일 수 있어요",
                description: "CHIPS 2차 배분 발표가 이번 주 예정돼 있어요.",
                newsTitle: "미 상무부, 반도체 보조금 2차 배분 임박"
            ),
            SignalCard(
                id: UUID(),
                intensity: .veryHigh,
                title: "실적 기대가 높아져 작은 실망에도 흔들릴 수 있어요",
                description: "최근 5일간 실적 관련 기대 뉴스가 평소의 3배 이상이에요.",
                newsTitle: "NVDA 실적 발표 앞두고 옵션 변동성 확대"
            ),
            SignalCard(
                id: UUID(),
                intensity: .veryHigh,
                title: "수출 규제 뉴스가 다시 가격에 반영되고 있어요",
                description: "정책 리스크 언급이 평소보다 빠르게 늘고 있어요.",
                newsTitle: "AI 칩 수출 규제 논의에 반도체주 압박"
            )
        ],
        timeline: [
            SignalTimelinePoint(weekLabel: "3주 전", returnPercent: 0.3, judgment: .watch),
            SignalTimelinePoint(weekLabel: "2주 전", returnPercent: -0.6, judgment: .caution),
            SignalTimelinePoint(weekLabel: "지난 주", returnPercent: -1.2, judgment: .caution),
            SignalTimelinePoint(weekLabel: "이번 주", returnPercent: -2.1, judgment: .action)
        ],
        checkpoints: [
            SignalCheckpointEvent(
                dateText: "5/30 (금)",
                title: "NVDA 실적 발표",
                description: "AI 수요 가이던스와 마진 전망이 반도체 흐름의 핵심이에요."
            )
        ]
    )

    static let noEvent = SignalSectorDetailSnapshot(
        sector: .financials,
        judgment: .caution,
        forecastReturnPercent: -0.4,
        currentPrice: "$41.20",
        expectedPrice: "$41.04",
        priceDelta: "-0.16",
        signalCards: [
            SignalCard(
                id: UUID(),
                intensity: .high,
                title: "금리 기대가 금융주 방향을 천천히 누르고 있어요",
                description: "최근 금리 인하 기대가 약해지며 은행주 뉴스 분위기가 흔들렸어요.",
                newsTitle: "장기금리 반등에 은행주 상승폭 축소"
            ),
            SignalCard(
                id: UUID(),
                intensity: .medium,
                title: "대출 수요 회복은 아직 뚜렷하지 않아요",
                description: "신용 수요 관련 뉴스가 평소보다 많아요.",
                newsTitle: "미 은행권, 대출 성장 둔화 우려 지속"
            )
        ],
        timeline: [
            SignalTimelinePoint(weekLabel: "3주 전", returnPercent: 0.1, judgment: .watch),
            SignalTimelinePoint(weekLabel: "2주 전", returnPercent: -0.1, judgment: .watch),
            SignalTimelinePoint(weekLabel: "지난 주", returnPercent: -0.2, judgment: .caution),
            SignalTimelinePoint(weekLabel: "이번 주", returnPercent: -0.4, judgment: .caution)
        ],
        checkpoints: []
    )

    static let newUser = SignalSectorDetailSnapshot(
        sector: .bigTech,
        judgment: .watch,
        forecastReturnPercent: 0.0,
        currentPrice: "$456.20",
        expectedPrice: "$456.20",
        priceDelta: "0.00",
        signalCards: [
            SignalCard(
                id: UUID(),
                intensity: .medium,
                title: "첫 데이터에서는 방향보다 기준선을 잡는 게 중요해요",
                description: "이번 주 빅테크 관련 신호는 아직 한 가지예요.",
                newsTitle: "FOMC 앞두고 빅테크 관망세 지속"
            )
        ],
        timeline: [
            nil,
            nil,
            nil,
            SignalTimelinePoint(weekLabel: "이번 주", returnPercent: 0.0, judgment: .watch)
        ],
        checkpoints: [
            SignalCheckpointEvent(
                dateText: "5/28 (수)",
                title: "FOMC 금리 결정",
                description: "첫 비교 기준이 될 이벤트라 발표 후 다시 확인하면 좋아요."
            )
        ]
    )
}

// MARK: - Previews

#Preview("A · 메인") {
    SignalSectorDetailView(snapshot: .main)
}

#Preview("B · 평온") {
    SignalSectorDetailView(snapshot: .calm)
}

#Preview("C · 강한 경고") {
    SignalSectorDetailView(snapshot: .strongWarning)
}

#Preview("D · 이벤트 없음") {
    SignalSectorDetailView(snapshot: .noEvent)
}

#Preview("E · 신규 사용자") {
    SignalSectorDetailView(snapshot: .newUser)
}
