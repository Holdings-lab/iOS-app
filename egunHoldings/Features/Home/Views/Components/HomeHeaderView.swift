import SwiftUI

struct HomeHeaderView: View {
    let profile: InvestorProfile

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.greeting)
                        .font(.pretendard(30, weight: .bold))
                        .foregroundStyle(Color.foreground)

                    Text("오늘 내 자산 브리핑")
                        .font(.pretendard(13, weight: .medium))
                        .foregroundStyle(Color.mutedForeground.opacity(0.78))
                }

                Spacer()

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.electricBlue.opacity(0.92), .policyPurple.opacity(0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(2)
                    }
                    .overlay {
                        Text(profile.initials)
                            .font(.pretendard(14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .glassEffect(.regular.tint(Color.white.opacity(0.05)), in: Circle())
            }
        }
        .padding(.top, 10)
    }
}
