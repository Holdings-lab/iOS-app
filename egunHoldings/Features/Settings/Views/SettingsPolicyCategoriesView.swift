import SwiftUI

struct SettingsPolicyCategoriesView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onBack: () -> Void

    @State private var selected: Set<String>

    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
        _selected = State(initialValue: viewModel.selectedPolicyCategoryIDs)
    }

    private var items: [MultiSelectGridItem] {
        SettingsMockData.policyCategories.map {
            MultiSelectGridItem(id: $0.id, icon: "", title: $0.title, subtitle: $0.subtitle)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavHeader(title: "관심 정책 카테고리", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    CalloutView(tone: .info, icon: "pencil") {
                        Text("정책 신호 분석에 사용돼요. 항목 구성은 계속 다듬어질 예정이에요.")
                    }
                    .padding(.top, 14)

                    MultiSelectGrid(items: items, selected: selected, max: nil) { id in
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
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
            .background(.ultraThinMaterial)
        }
    }

    private func save() {
        viewModel.savePolicyCategories(selected)
        onBack()
    }
}
