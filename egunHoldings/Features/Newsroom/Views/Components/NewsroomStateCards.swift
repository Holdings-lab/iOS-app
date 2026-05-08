import SwiftUI

struct NewsroomLoadingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.brand)
            VStack(alignment: .leading, spacing: 4) {
                Text("출퇴근용 브리핑을 압축하는 중이에요")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("긴 기사 대신 핵심만 먼저 읽을 수 있게 정리하고 있어요.")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
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

struct NewsroomEmptyCard: View {
    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.muted)
                    .frame(width: 52, height: 52)
                Image(systemName: "newspaper")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.textDisabled)
            }

            VStack(spacing: 6) {
                Text("지금은 새로운 이슈가 없어요")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("정책 이벤트가 생기면 여기에 바로 표시돼요.\n잠시 후 다시 확인해보세요.")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard()
    }
}
