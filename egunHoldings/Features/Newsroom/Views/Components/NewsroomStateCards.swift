import SwiftUI

struct NewsroomErrorCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textPrimary)

            Button("다시 불러오기") {
                onRetry()
            }
            .font(.pretendard(13, weight: .semibold))
            .foregroundStyle(Color.brand)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}
