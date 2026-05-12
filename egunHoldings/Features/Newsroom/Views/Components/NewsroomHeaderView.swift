import SwiftUI

struct NewsroomHeaderView: View {
    let latestUpdateText: String
    let selectedCategoryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

                        Text("관심 산업의 시장 흐름과 기사 요약만 빠르게 봐요")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(latestUpdateText) 업데이트")
                        .font(.pretendard(11, weight: .semibold))
                        .foregroundStyle(Color.brand)
                    Text("관심 산업 \(selectedCategoryCount)개")
                        .font(.pretendard(11, weight: .medium))
                        .foregroundStyle(Color.textQuaternary)
                }
            }
        }
    }
}
