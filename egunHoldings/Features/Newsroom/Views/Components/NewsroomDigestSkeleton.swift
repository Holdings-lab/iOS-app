import SwiftUI

/// 최초 로드 스켈레톤 (§4.4). 실제 섹션 구조를 유지해 무엇이 로딩 중인지 알 수 있게 한다
/// — 오늘탭 `TodaySkeletonViews` (.redacted(reason: .placeholder)) 관례.
struct NewsroomDigestSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            KDXCard {
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 180, height: 18)
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(height: 14)
                    RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 220, height: 14)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 90, height: 16)

                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: KDXRadius.card).fill(Color.divider).frame(height: 48)
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}
