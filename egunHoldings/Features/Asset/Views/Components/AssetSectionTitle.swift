import SwiftUI

struct AssetSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.pretendard(15, weight: .semibold))
            .foregroundStyle(Color.textPrimary)
    }
}

extension View {
    func assetGradientCTA() -> some View {
        foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Color.electricBlue, Color.policyPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
            )
            .shadow(color: Color.electricBlue.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}
