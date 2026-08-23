import SwiftUI
import UIKit

extension Font {
    static func pretendard(_ size: CGFloat, weight: Weight = .regular) -> Font {
        guard let resolvedName = resolvedFontName(for: weight) else {
            return .system(size: size, weight: weight, design: .default)
        }
        return .custom(resolvedName, size: size)
    }

    static func pretendard(
        _ size: CGFloat,
        weight: Weight = .regular,
        relativeTo textStyle: TextStyle
    ) -> Font {
        guard let resolvedName = resolvedFontName(for: weight) else {
            return .system(textStyle, design: .default, weight: weight)
        }
        return .custom(resolvedName, size: size, relativeTo: textStyle)
    }

    private static func pretendardName(for weight: Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "Pretendard-Bold"
        case .semibold:
            return "Pretendard-SemiBold"
        case .medium:
            return "Pretendard-Medium"
        default:
            return "Pretendard-Regular"
        }
    }

    /// 폰트 등록 여부는 앱 수명 동안 바뀌지 않는데, 기존 구현은 `body`가 재평가될 때마다
    /// (스크롤 등으로 초당 수십~수백 회) `UIFont(name:)`을 호출해 존재 여부를 확인했다.
    /// 웨이트별 결과를 한 번만 계산해 캐싱하고, 이후에는 캐시된 이름 조립만 수행한다.
    private static func resolvedFontName(for weight: Weight) -> String? {
        let weightedName = pretendardName(for: weight)

        if let cached = resolutionCache[weightedName] {
            return cached
        }

        let resolved: String?
        if UIFont(name: weightedName, size: 12) != nil {
            resolved = weightedName
        } else if UIFont(name: "Pretendard", size: 12) != nil {
            resolved = "Pretendard"
        } else {
            resolved = nil
        }

        resolutionCache[weightedName] = resolved
        return resolved
    }

    private static var resolutionCache: [String: String?] = [:]
}
