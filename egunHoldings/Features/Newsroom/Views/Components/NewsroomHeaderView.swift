import SwiftUI

struct NewsroomHeaderView: View {
    let latestUpdateText: String
    @Binding var digestMode: NewsroomDigestMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("뉴스")
                            .font(.pretendard(26, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .tracking(-0.5)

                        Text("내 자산과 가까운 기사부터 압축해서 봐요")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(latestUpdateText) 업데이트")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.brand)
                    Text("압축 브리핑")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.textQuaternary)
                }
            }

            HStack(spacing: 4) {
                ForEach(NewsroomDigestMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            digestMode = mode
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(mode.rawValue)
                                .font(.pretendard(12, weight: .bold))
                            Text(mode.subtitle)
                                .font(.pretendard(10, weight: .medium))
                        }
                        .foregroundStyle(digestMode == mode ? Color.electricBlue : Color.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            digestMode == mode ? Color.electricBlue.opacity(0.15) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
    }
}
