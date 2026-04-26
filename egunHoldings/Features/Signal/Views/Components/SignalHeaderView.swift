import SwiftUI

struct SignalHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(Color.electricBlue)
                Text("시그널 센터")
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(Color.foreground)
            }

            Text("정책이 만드는 투자 기회를 포착하세요")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
            
            Text("행동 옵션, 근거, 무효화 조건을 같이 보고 먼저 모의 반영해보세요")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
