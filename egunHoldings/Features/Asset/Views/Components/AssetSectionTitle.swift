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
        foregroundStyle(Color.textOnAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Color.brand, Color.brandDark],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
            )
    }
}
