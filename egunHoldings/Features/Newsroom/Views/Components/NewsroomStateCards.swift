import SwiftUI

struct NewsroomLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.electricBlue)
                Text("출퇴근용 브리핑을 압축하는 중이에요")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text("긴 기사 대신 핵심만 먼저 읽을 수 있게 정리하고 있어요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}

struct NewsroomErrorCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.foreground)

            Button("다시 불러오기") {
                onRetry()
            }
            .font(.pretendard(13, weight: .semibold))
            .foregroundStyle(Color.electricBlue)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}

struct NewsroomEmptyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "newspaper")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.mutedForeground.opacity(0.6))

                Text("지금은 새로운 이슈가 없어요")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.foreground)
            }

            Text("정책 이벤트가 생기면 여기에 바로 표시돼요.\n잠시 후 다시 확인해보세요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}
