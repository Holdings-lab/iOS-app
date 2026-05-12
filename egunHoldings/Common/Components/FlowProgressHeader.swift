import SwiftUI

struct FlowProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    var stepTitle: String? = nil
    var showsBack: Bool = true
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                if showsBack {
                    LiquidGlassBackButton(action: onBack)
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let stepTitle {
                        Text(stepTitle)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.brand)
                    }

                    Text("\(currentStep)/\(totalSteps)")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            FlowProgressBar(progress: Double(currentStep) / Double(totalSteps))
        }
    }
}

struct LiquidGlassBackButton: View {
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    init(
        accessibilityLabel: LocalizedStringKey = "뒤로가기",
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    VStack {
        FlowProgressHeader(currentStep: 2, totalSteps: 3, onBack: {})
        Spacer()
    }
    .padding(24)
    .background(PFGradientBackground())
}
