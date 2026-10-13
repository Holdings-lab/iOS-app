import SwiftUI

struct AssetLoadingState: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView().tint(AssetTabPalette.brand)
            Text("자산을 불러오는 중이에요")
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(AssetTabPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AssetEmptyState: View {
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.pie")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AssetTabPalette.brand)
                .frame(width: 68, height: 68)
                .background(AssetTabPalette.brandSoft, in: Circle())
            Text("연결한 계좌가 없어요")
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)
            Text("한국투자증권 모의투자 계좌를 연결하면\n보유 종목과 평가금액을 불러와요.")
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button("계좌 연결하기", action: onConnect)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AssetTabPalette.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AssetTabPalette.divider, lineWidth: 1)
        }
        .padding(.horizontal, PSSpacing.screenHorizontal)
        .frame(maxHeight: .infinity)
    }
}

struct AssetErrorState: View {
    let message: String
    let onRetry: () -> Void
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AssetTabPalette.down)
            Text("자산을 불러오지 못했어요")
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(AssetTabPalette.textPrimary)
            Text(message)
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(AssetTabPalette.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button("다시 시도", action: onRetry)
                    .buttonStyle(AssetSecondaryButtonStyle())
                Button("계좌 연결", action: onConnect)
                    .buttonStyle(AssetPrimaryButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, PSSpacing.screenHorizontal)
        .frame(maxHeight: .infinity)
    }
}
