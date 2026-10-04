import SwiftUI

// MARK: - Goal Progress (Section 3)

struct TodayGoalProgressCard: View {
    let goalProgress: TodayGoalProgress?
    let onSetGoal: () -> Void

    var body: some View {
        KDXCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("목표 대비")
                        .font(.pretendard(15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    if let goalProgress {
                        Text(goalProgress.displayStatusLabel)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(goalProgress.displayColor)
                    }
                }

                if let goalProgress {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.muted)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(goalProgress.displayColor)
                                .frame(width: proxy.size.width * CGFloat(goalProgress.clampedProgressPercent) / 100.0)
                                .animation(.easeInOut(duration: 0.5), value: goalProgress.progressPercent)
                        }
                    }
                    .frame(height: 8)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(goalProgress.progressPercent)%")
                            .font(.pretendard(20, weight: .bold))
                            .foregroundStyle(goalProgress.isGoalAchieved ? Color.brand : Color.textPrimary)
                            .monospacedDigit()
                        Text("\(goalProgress.goalLabel) · \(goalProgress.scheduleDeltaText)")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 2)
                } else {
                    TodayQuietState(
                        message: Text("아직 목표 자금을 설정하지 않았어요"),
                        ctaTitle: "목표 설정하기",
                        onCTA: onSetGoal
                    )
                }
            }
        }
    }
}
