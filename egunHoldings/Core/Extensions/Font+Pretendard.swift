import SwiftUI
import UIKit

extension Font {
    static func pretendard(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let weightedName = pretendardName(for: weight)

        if UIFont(name: weightedName, size: size) != nil {
            return .custom(weightedName, size: size)
        }

        if UIFont(name: "Pretendard", size: size) != nil {
            return .custom("Pretendard", size: size)
        }

        return .system(size: size, weight: weight, design: .default)
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
}
