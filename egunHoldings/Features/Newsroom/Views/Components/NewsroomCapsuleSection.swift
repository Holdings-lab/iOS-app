import SwiftUI

struct NewsroomMarketTickerTape: View {
    let tickers: [NewsroomMarketTicker]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Markets", systemImage: "waveform.path.ecg")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text("관심 산업 지표")
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tickers) { ticker in
                        NewsroomTickerCard(ticker: ticker)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }
}

struct NewsroomCategorySelector: View {
    @Binding var selectedCategories: Set<PolicyNewsCategory>
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("관심 산업")
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button(action: onEdit) {
                    Label("편집", systemImage: "slider.horizontal.3")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(Color.brandTintBg, in: Capsule(style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PolicyNewsCategory.allCases, id: \.self) { category in
                        NewsroomCategoryChip(
                            category: category,
                            isSelected: selectedCategories.contains(category)
                        ) {
                            toggle(category)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
        .padding(14)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func toggle(_ category: PolicyNewsCategory) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
    }
}

struct NewsroomCategoryEditorSheet: View {
    @Binding var selectedCategories: Set<PolicyNewsCategory>
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule(style: .continuous)
                .fill(Color.hairline)
                .frame(width: 42, height: 4)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text("관심 산업 편집")
                    .font(.pretendard(22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("선택한 산업의 시장 지표와 관련 뉴스만 뉴스 탭에 모아봅니다.")
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(PolicyNewsCategory.allCases, id: \.self) { category in
                    NewsroomCategoryEditorTile(
                        category: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        toggle(category)
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                if selectedCategories.isEmpty {
                    selectedCategories = [.semiconductor, .ai, .energy]
                }
                dismiss()
            } label: {
                Text("완료")
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }

    private func toggle(_ category: PolicyNewsCategory) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
    }
}

struct NewsroomIndustrySummarySection: View {
    let title: String
    let subtitle: String
    let items: [PolicyNewsItem]
    let isSaved: (PolicyNewsItem) -> Bool
    let onSelect: (PolicyNewsItem) -> Void
    let onToggleSave: (PolicyNewsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(title)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)

                Spacer()
            }

            if items.isEmpty {
                NewsroomNoIndustryNewsCard()
            } else {
                ForEach(items) { item in
                    IndustryNewsSummaryCard(
                        item: item,
                        isSaved: isSaved(item),
                        onSelect: { onSelect(item) },
                        onToggleSave: { onToggleSave(item) }
                    )
                }
            }
        }
    }
}

struct NewsroomInfoBox: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.25))
                .padding(.top, 2)

            Text("뉴스 탭은 선택한 관심 산업의 시장 흐름과 기사 요약을 보여줍니다. 내 자산 기준 분석은 오늘 탭의 정책 리포트에서 확인할 수 있습니다.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.3))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .softGlassCard()
    }
}

struct NewsInvestmentDisclaimer: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mutedForeground.opacity(0.25))
                .padding(.top, 2)

            Text("이 해설은 투자 권유가 아니며, 정책 변화에 대한 해석입니다.")
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.3))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NewsAssetTagFlow: View {
    let tags: [NewsroomAssetTag]

    var body: some View {
        NewsTagFlowLayout {
            ForEach(tags) { tag in
                Text(tag.title)
                    .font(.pretendard(10, weight: .bold))
                    .foregroundStyle(tag.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        tag.color.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: KDXRadius.chip, style: .continuous)
                    )
            }
        }
    }
}

private struct NewsroomTickerCard: View {
    let ticker: NewsroomMarketTicker

    private var changeColor: Color {
        ticker.isPositive ? Color.emerald : Color.policyCoral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ticker.title)
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(ticker.price)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(ticker.changeText)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(changeColor)
                    .monospacedDigit()
                    .lineLimit(1)
            }

            SparklineView(values: ticker.sparkline, color: changeColor)
                .frame(height: 30)
        }
        .frame(width: 148, alignment: .leading)
        .padding(12)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

private struct NewsroomCategoryChip: View {
    let category: PolicyNewsCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.newsroomIconName)
                    .font(.system(size: 12, weight: .bold))
                Text(category.title)
                    .font(.pretendard(12, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.textOnAccent : category.color)
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(
                isSelected ? category.color : category.color.opacity(0.10),
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.clear : category.color.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct NewsroomCategoryEditorTile: View {
    let category: PolicyNewsCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: category.newsroomIconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(category.color)
                        .frame(width: 34, height: 34)
                        .background(category.color.opacity(0.12), in: Circle())

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.brand : Color.textDisabled)
                }

                Text(category.title)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(12)
            .background(
                isSelected ? category.color.opacity(0.08) : Color.subtle,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? category.color.opacity(0.35) : Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct IndustryNewsSummaryCard: View {
    let item: PolicyNewsItem
    let isSaved: Bool
    let onSelect: () -> Void
    let onToggleSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 8) {
                        NewsCategoryBadge(category: item.category)

                        Text(item.newsroomSourceTimeText)
                            .font(.pretendard(10, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Image(systemName: item.sentiment.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(item.newsroomDirectionColor)
                            .frame(width: 28, height: 28)
                            .background(item.newsroomDirectionColor.opacity(0.12), in: Circle())
                    }

                    Text(item.title)
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.summary)
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    NewsAssetTagFlow(tags: item.newsroomAssetTags)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button(action: onSelect) {
                    Label("1분 요약 보기", systemImage: "doc.text")
                        .font(.pretendard(12, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())

                Button(action: onToggleSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSaved ? Color.brand : Color.textTertiary)
                        .frame(width: 44, height: 40)
                        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(isSaved ? "저장 해제" : "저장")
            }
        }
        .padding(14)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

private struct NewsroomNoIndustryNewsCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "newspaper")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.textDisabled)

            Text("선택한 산업의 뉴스가 아직 없어요")
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textSecondary)

            Text("관심 산업을 추가하거나 잠시 후 다시 확인해주세요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .softGlassCard()
    }
}

private struct NewsCategoryBadge: View {
    let category: PolicyNewsCategory

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: category.newsroomIconName)
                .font(.system(size: 10, weight: .bold))
            Text(category.title)
                .font(.pretendard(10, weight: .bold))
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(category.color.opacity(0.12), in: Capsule(style: .continuous))
    }
}

private struct SparklineView: View {
    let values: [CGFloat]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }

            var path = Path()
            let clamped = values.map { min(1, max(0, $0)) }
            let stepX = size.width / CGFloat(max(clamped.count - 1, 1))

            for index in clamped.indices {
                let x = CGFloat(index) * stepX
                let y = size.height * (1 - clamped[index])
                let point = CGPoint(x: x, y: y)

                if index == clamped.startIndex {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            context.stroke(path, with: .color(color), lineWidth: 2)
        }
        .accessibilityHidden(true)
    }
}

private struct NewsTagFlowLayout: Layout {
    private let spacing: CGFloat = 6
    private let rowSpacing: CGFloat = 6

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0, x + size.width > maxWidth {
                measuredWidth = max(measuredWidth, x - spacing)
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        measuredWidth = max(measuredWidth, max(0, x - spacing))
        return CGSize(width: proposal.width ?? measuredWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
