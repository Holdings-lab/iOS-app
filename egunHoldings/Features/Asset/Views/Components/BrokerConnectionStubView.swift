import SwiftUI

struct BrokerConnectionStubView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.electricBlue.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.electricBlue)
            }

            Text("증권사 계좌 연결")
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text("현재는 목 데이터 단계입니다.\n추후 실제 계좌 연결 API를 이 화면에 붙일 예정이에요.")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
                .multilineTextAlignment(.center)

            Button("닫기", action: onDismiss)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Color.electricBlue, in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous))
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.elevated.ignoresSafeArea())
    }
}
