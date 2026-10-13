import SwiftUI

struct AssetConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isConnecting: Bool
    let errorMessage: String?
    let onConnect: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("증권사 선택")
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(AssetTabPalette.brand)
                    Text("어떤 계좌를 연결할까요?")
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(AssetTabPalette.textPrimary)
                    Text("한국투자증권 모의투자 계좌를 연결하면 보유 종목과 평가금액을 불러옵니다.")
                        .font(.pretendard(15, weight: .regular))
                        .foregroundStyle(AssetTabPalette.textSecondary)
                        .lineSpacing(4)

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AssetTabPalette.brand)
                        Text("앱은 증권사 자격증명을 입력받거나 저장하지 않아요.")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(AssetTabPalette.textSecondary)
                    }
                    .padding(16)
                    .background(AssetTabPalette.brandSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("한국투자증권")
                            .font(.pretendard(16, weight: .bold))
                            .foregroundStyle(AssetTabPalette.textPrimary)
                        Text("모의투자 · 읽기 전용")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(AssetTabPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AssetTabPalette.brand, lineWidth: 1.5)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(AssetTabPalette.down)
                    }

                    Button(action: onConnect) {
                        HStack(spacing: 8) {
                            if isConnecting { ProgressView().tint(.white) }
                            Text(isConnecting ? "연결하는 중..." : "연결하고 자산 불러오기")
                        }
                    }
                    .buttonStyle(AssetPrimaryButtonStyle())
                    .disabled(isConnecting)
                }
                .padding(20)
            }
            .background(AssetTabPalette.screen)
            .navigationTitle("자산 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct AssetPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard(15, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AssetTabPalette.brand.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct AssetSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard(15, weight: .bold))
            .foregroundStyle(AssetTabPalette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AssetTabPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AssetTabPalette.divider, lineWidth: 1)
            }
    }
}
