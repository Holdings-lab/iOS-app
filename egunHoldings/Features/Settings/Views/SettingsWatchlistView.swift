import SwiftUI

struct SettingsWatchlistView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onBack: () -> Void

    @State private var selected: Set<String>

    private static let maxSelection = 5

    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
        _selected = State(initialValue: Set(viewModel.selectedWatchSectors.map(\.rawValue)))
    }

    private var items: [MultiSelectGridItem] {
        WatchAssetSector.allCases.map {
            MultiSelectGridItem(id: $0.rawValue, icon: $0.emoji, title: $0.title, subtitle: $0.subtitle)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavHeader(title: "관심 분야", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("최소 1개, 최대 \(Self.maxSelection)개까지 고를 수 있어요")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        Spacer()

                        SettingsCounterPill(count: selected.count, max: Self.maxSelection)
                    }
                    .padding(.top, 14)

                    MultiSelectGrid(items: items, selected: selected, max: Self.maxSelection) { id in
                        if selected.contains(id) {
                            selected.remove(id)
                        } else {
                            selected.insert(id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 118)
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(action: save) {
                Text("저장")
                    .font(.pretendard(14.5, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(selected.isEmpty ? Color.muted : Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selected.isEmpty)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
            .background(.ultraThinMaterial)
        }
    }

    private func save() {
        let sectors = Set(selected.compactMap(WatchAssetSector.init(rawValue:)))
        viewModel.saveWatchSectors(sectors)
        onBack()
    }
}
