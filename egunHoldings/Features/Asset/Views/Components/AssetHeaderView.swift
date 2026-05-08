import SwiftUI

struct AssetHeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.electricBlue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Color.electricBlue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("내 자산")
                    .font(.pretendard(26, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .tracking(-0.5)

                Text("나는 지금 어디에 노출돼 있지?")
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(Color.mutedForeground)
            }

            Spacer()
        }
    }
}
