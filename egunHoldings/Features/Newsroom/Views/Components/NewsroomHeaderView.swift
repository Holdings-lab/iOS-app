import SwiftUI

struct NewsroomHeaderView: View {
    let latestUpdateText: String
    @Binding var digestMode: NewsroomDigestMode

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "newspaper.fill")
                            .foregroundStyle(Color.electricBlue)
                        Text("뉴스룸")
                            .font(.pretendard(28, weight: .bold))
                            .foregroundStyle(Color.foreground)
                    }

                    Text("긴 기사 대신 4줄 브리핑으로 출퇴근 중 빠르게 읽는 탭")
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(latestUpdateText) 업데이트")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                    Text("압축 브리핑")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                }
            }

            HStack(spacing: 8) {
                ForEach(NewsroomDigestMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            digestMode = mode
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(mode.rawValue)
                                .font(.pretendard(12, weight: .semibold))
                            Text(mode.subtitle)
                                .font(.pretendard(10, weight: .medium))
                        }
                        .foregroundStyle(digestMode == mode ? Color.electricBlue : Color.mutedForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            (digestMode == mode ? Color.electricBlue.opacity(0.14) : Color.white.opacity(0.03)),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    digestMode == mode ? Color.electricBlue.opacity(0.35) : Color.white.opacity(0.06),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
