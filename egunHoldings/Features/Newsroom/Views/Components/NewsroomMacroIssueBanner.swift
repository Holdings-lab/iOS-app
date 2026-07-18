import SwiftUI

/// 두 개 이상 보유 종목 피드에 같은 기사가 겹쳤을 때만 나타나는 예외 배너.
/// 별도 애니메이션이나 햅틱 없이 다른 카드와 같은 정적 위계로 노출한다.
struct NewsroomMacroIssueBanner: View {
    let issue: NewsroomMacroIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 11, weight: .bold))

                Text("포트폴리오 공통 이슈")
                    .font(.pretendard(11.5, weight: .bold))
            }
            .foregroundStyle(Color.brand)

            Text(issue.headline)
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(issue.summary)
                .font(.pretendard(13.5, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(issue.affectedTickers.joined(separator: " · "))
                .font(.pretendard(11.5, weight: .bold))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.brand.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
