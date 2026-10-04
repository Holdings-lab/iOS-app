import SwiftUI

struct OnboardingV3QuestionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(28, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.pretendard(15, weight: .regular))
                .foregroundStyle(OnboardingV3Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }
}

private struct OnboardingRevealModifier: ViewModifier {
    let isRevealed: Bool
    let index: Int
    let baseDelay: Double
    let step: Double

    func body(content: Content) -> some View {
        content
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : 8)
            .animation(
                .easeOut(duration: 0.28).delay(baseDelay + Double(index) * step),
                value: isRevealed
            )
    }
}

extension View {
    /// 콘텐츠가 하나씩(index 순서대로) 순차 등장하도록 만든다. 리스트가 아닌 단일 블록은
    /// index 기본값 0으로 두면 한 번에 페이드인된다.
    func onboardingReveal(isRevealed: Bool, index: Int = 0, baseDelay: Double = 0, step: Double = 0.06) -> some View {
        modifier(OnboardingRevealModifier(isRevealed: isRevealed, index: index, baseDelay: baseDelay, step: step))
    }

    /// 진입 시 콘텐츠를 살짝 늦춰 등장시켜 onboardingReveal의 순차 등장이 시작될 기준점을 만든다.
    /// reduceMotion이 켜져 있으면 지연 없이 바로 전체를 보여준다.
    func onboardingRevealSequence(
        isRevealed: Binding<Bool>,
        reduceMotion: Bool
    ) -> some View {
        task {
            guard !reduceMotion else {
                isRevealed.wrappedValue = true
                return
            }

            try? await Task.sleep(nanoseconds: 80_000_000)
            isRevealed.wrappedValue = true
        }
    }
}
struct OnboardingV3ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnboardingV3Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    func onboardingV3Background() -> some View {
        modifier(OnboardingV3ScreenBackground())
    }

    func trackOnboardingProgressScroll(isCollapsed: Binding<Bool>) -> some View {
        coordinateSpace(name: OnboardingProgressCoordinateSpace.name)
            .onPreferenceChange(OnboardingProgressScrollOffsetKey.self) { offset in
                let nextValue = offset < -10
                guard isCollapsed.wrappedValue != nextValue else { return }
                isCollapsed.wrappedValue = nextValue
            }
    }

    func onboardingProgressOverlay(step: Int, totalSteps: Int = 2, isCollapsed: Bool) -> some View {
        overlay(alignment: .top) {
            ProgressBar(step: step, totalSteps: totalSteps, isCollapsed: isCollapsed)
                .padding(.top, OnboardingV3Layout.progressTop)
        }
    }
}
