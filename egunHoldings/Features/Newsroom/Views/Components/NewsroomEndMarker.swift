import SwiftUI

/// 리스트 종료 마커 (§1.6). 이 아래엔 어떤 콘텐츠도 두지 않는다 —
/// "더 보기", 추천, 무한 로딩 금지. 콘텐츠가 유한하다는 것 자체가 안심 신호다.
struct NewsroomEndMarker: View {
    let heartbeatText: String?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                line
                Text("오늘 브리핑은 여기까지예요")
                    .font(.pretendard(11.5, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
                    .lineLimit(1)
                    .fixedSize()
                line
            }

            if let heartbeatText {
                Text(heartbeatText)
                    .font(.pretendard(11, weight: .medium))
                    .foregroundStyle(Color.textQuaternary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1)
    }
}
