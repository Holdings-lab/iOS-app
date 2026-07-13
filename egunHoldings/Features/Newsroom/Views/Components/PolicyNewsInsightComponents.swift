import SwiftUI

struct DetailDisclosureCard<Content: View>: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color
    private let content: Content

    @State private var isExpanded: Bool

    init(
        title: String,
        subtitle: String,
        iconName: String,
        tint: Color,
        isExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tint = tint
        self.content = content()
        _isExpanded = State(initialValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 14)
        } label: {
            InsightSectionHeader(title: title, subtitle: subtitle, iconName: iconName, tint: tint)
        }
        .tint(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

struct AssetImpactMeterList: View {
    let tags: [NewsroomAssetTag]
    let tint: Color

    var body: some View {
        VStack(spacing: 9) {
            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                AssetImpactMeterRow(
                    title: tag.title,
                    value: impactValue(for: index),
                    color: tag.color
                )
            }
        }
        .padding(12)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func impactValue(for index: Int) -> Double {
        min(0.88, 0.52 + Double(index) * 0.14)
    }
}

struct AssetImpactMeterRow: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(value * 100))% 연결")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.hairline)

                    Capsule(style: .continuous)
                        .fill(color)
                        .frame(width: max(0, proxy.size.width * value))
                }
            }
            .frame(height: 6)
        }
    }
}

struct LearningGuideCard: View {
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("학습 가이드")
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(tint)

                Text("이런 정책은 자산에 어떤 영향을 줄까?")
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("금리, 보조금, 규제 뉴스가 ETF와 개별 종목에 전달되는 경로를 짧게 복습할 수 있어요.")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

struct InsightSectionHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()
        }
    }
}

enum InsightRowStyle {
    case numbered
    case check
    case dot
}

struct InsightVisualCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color
    let rows: [String]
    let style: InsightRowStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(title: title, subtitle: subtitle, iconName: iconName, tint: tint)

            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    InsightRow(index: index + 1, text: row, tint: tint, style: style)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

struct InsightRow: View {
    let index: Int
    let text: String
    let tint: Color
    let style: InsightRowStyle

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            indicator
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 16) {
                Text(text)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.subtle.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var indicator: some View {
        switch style {
        case .numbered:
            Text("\(index)")
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: Circle())
        case .check:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.textOnAccent)
                .frame(width: 24, height: 24)
                .background(tint, in: Circle())
        case .dot:
            Circle()
                .fill(tint.opacity(0.7))
                .frame(width: 8, height: 8)
                .frame(width: 24, height: 24)
        }
    }
}

struct ScenarioTile: View {
    let title: String
    let text: String
    let tint: Color
    let strength: Double

    init(title: String, text: String, tint: Color, strength: Double = 0.58) {
        self.title = title
        self.text = text
        self.tint = tint
        self.strength = strength
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(tint)

                Spacer()

                Text("\(Int(strength * 100))%")
                    .font(.pretendard(10, weight: .bold))
                    .foregroundStyle(tint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.14))

                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: max(0, proxy.size.width * strength))
                }
            }
            .frame(height: 5)

            Text(text)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        }
    }
}

typealias NewsInsightSheet = PolicyNewsInsightDetailView

#Preview {
    NavigationStack {
        PolicyNewsInsightDetailView(
            item: HomeNewsMockData.items[0],
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: previewViewModel()
        )
    }
}

@MainActor
private func previewViewModel() -> PolicyNewsViewModel {
    let viewModel = PolicyNewsViewModel(repository: MockPolicyNewsRepository())
    viewModel.presentInsight(for: HomeNewsMockData.items[0], userAssetProfile: AppMockData.userAssetProfile)
    return viewModel
}
