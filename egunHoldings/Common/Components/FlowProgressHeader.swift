import SwiftUI

struct FlowProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    var showsBack: Bool = true
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                if showsBack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("이전")
                        }
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 42, height: 20)
                }

                Spacer()

                Text("\(currentStep)/\(totalSteps)")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            FlowProgressBar(progress: Double(currentStep) / Double(totalSteps))
        }
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
