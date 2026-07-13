import SwiftUI

/// "이게 무슨 뜻인가요?" 인라인 번역 (§3). 시트를 띄우지 않고 버튼 자리에서
/// 아래로 펼쳐진다 — 읽기 흐름이 세로로 끊기지 않는 게 목적. 접기 가능.
struct NewsroomInlineTranslationBlock: View {
    let content: String

    @State private var isExpanded = false
    @State private var isLoading = false

    var body: some View {
        // 토글 버튼과 번역 본문이 배경 한 장을 공유하는 단일 카드 —
        // 펼침 시 같은 카드가 아래로 확장되고, 헤더 행을 다시 탭하면 접힌다.
        VStack(alignment: .leading, spacing: 0) {
            Button {
                toggle()
            } label: {
                HStack(spacing: 6) {
                    Text("이게 무슨 뜻인가요?")
                        .font(.pretendard(13.5, weight: .bold))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleButtonStyle())

            if isExpanded {
                Divider()
                    .overlay(Color.hairline)
                    .padding(.horizontal, 14)

                Group {
                    if isLoading {
                        loadingSkeleton
                    } else {
                        Text(content)
                            .font(.pretendard(14.5, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(height: 13)
            RoundedRectangle(cornerRadius: 6).fill(Color.divider).frame(width: 180, height: 13)
        }
        .redacted(reason: .placeholder)
    }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isExpanded.toggle()
        }

        guard isExpanded else { return }
        isLoading = true

        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.16)) {
                isLoading = false
            }
        }
    }
}
