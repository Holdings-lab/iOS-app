import Foundation

nonisolated enum AppVocabulary {
    enum Asset {
        static let policyExposureTab = "정책 노출"
        static let rebalancingTab = "조정 제안"
        static let exposureSummary = "영향이 큰 정책 TOP"
        static let defenseConcentration = "안전망·쏠림 정도"
        static let policyMatrix = "자산별 정책 영향"
        static let hiddenPolicyBets = "함께 흔들릴 자산"
    }

    enum Rebalancing {
        static let weeklyTitle = "이번 주 조정 제안"
        static let recommendedAdjustment = "추천 조정"
        static let adjustmentSuggestions = "조정 제안"
        static let appliedCriteria = "적용된 기준"
        static let targetCashWeight = "유지할 현금 비중"
        static let rebalanceThreshold = "조정 시작 편차"
        static let maxSingleAssetWeight = "한 자산 최대 비중"
        static let minTradeAmount = "최소 거래 금액"
        static let currentWeight = "현재 비중"
        static let targetWeight = "목표 비중"
        static let currentPrice = "현재 가격"
        static let currentValue = "보유 금액"
        static let drift = "목표 대비 차이"
        static let explanationTitle = "왜 이런 제안인가요?"

        static func differenceText(diff: String, isOverTarget: Bool) -> String {
            if diff == "0.0%p" {
                return "차이: 목표와 거의 같음"
            }

            let direction = isOverTarget ? "높음" : "낮음"
            return "차이: 목표보다 \(diff) \(direction)"
        }

        static func actionProposalText(actionSummary: String, tradeAmount: String) -> String {
            "조정 제안: \(actionSummary) (\(tradeAmount))"
        }

        static func reasonText(
            for rawCode: String,
            profile: String,
            targetWeight: String,
            diff: String,
            limit: String,
            cashRatio: String,
            amount: String,
            threshold: String
        ) -> String {
            switch RebalancingReasonCode(rawValue: rawCode) {
            case .onboardingProfileApplied:
                return "온보딩에서 선택한 \(profile) 적용"
            case .targetWeightCalculated:
                return "목표 비중 \(targetWeight) 계산 완료"
            case .underTargetWeight:
                return "현재 비중이 목표보다 \(diff) 낮음"
            case .overTargetWeight:
                return "현재 비중이 목표보다 \(diff) 높음"
            case .withinTolerance, .driftWithinThreshold:
                return "허용 범위 안에 있음"
            case .singleAssetLimitExceeded, .exceedsSingleAssetLimit:
                return "한 자산 최대 비중 \(limit) 초과"
            case .cashRatioTarget:
                return "유지할 현금 비중 \(cashRatio) 적용"
            case .minTradeAmountApplied:
                return "최소 거래 금액 \(amount) 적용"
            case .rebalanceThresholdTriggered, .driftExceedsThreshold:
                return "편차 \(threshold) 이상이라 조정 트리거"
            case .none:
                return "계산 기준을 확인했습니다."
            }
        }
    }

    enum ErrorMessage {
        static let serverFallback = "지금 서버에 연결할 수 없어요. 예시 데이터로 보여드릴게요."
        static let loginExpired = "로그인이 만료되었어요. 다시 들어와 주세요."
        static let timeout = "응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요."
        static let network = "인터넷 연결을 확인해 주세요."
        static let unknown = "잠시 후 다시 시도해 주세요."

        static func userFacing(for error: Error, fallback: String = unknown) -> String {
            if let networkError = error as? NetworkError {
                return userFacing(for: networkError, fallback: fallback)
            }

            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    return timeout
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    return network
                default:
                    return network
                }
            }

            return fallback
        }

        static func userFacing(for error: NetworkError, fallback: String = unknown) -> String {
            switch error {
            case .apiFailure(let statusCode, _, _):
                return userFacing(statusCode: statusCode, fallback: fallback)
            case .httpStatus(let statusCode):
                return userFacing(statusCode: statusCode, fallback: fallback)
            case .invalidURL, .invalidResponse, .emptyResult, .decodingFailed, .notImplemented:
                return serverFallback
            case .missingRefreshToken:
                return loginExpired
            }
        }

        private static func userFacing(statusCode: Int?, fallback: String) -> String {
            switch statusCode {
            case 401, 403:
                return loginExpired
            case 404, 500:
                return serverFallback
            case 408:
                return timeout
            case nil:
                return fallback
            default:
                return fallback
            }
        }
    }
}

nonisolated enum RebalancingReasonCode: String {
    case onboardingProfileApplied = "ONBOARDING_PROFILE_APPLIED"
    case targetWeightCalculated = "TARGET_WEIGHT_CALCULATED"
    case underTargetWeight = "UNDER_TARGET_WEIGHT"
    case overTargetWeight = "OVER_TARGET_WEIGHT"
    case withinTolerance = "WITHIN_TOLERANCE"
    case singleAssetLimitExceeded = "SINGLE_ASSET_LIMIT_EXCEEDED"
    case cashRatioTarget = "CASH_RATIO_TARGET"
    case minTradeAmountApplied = "MIN_TRADE_AMOUNT_APPLIED"
    case rebalanceThresholdTriggered = "REBALANCE_THRESHOLD_TRIGGERED"

    case driftExceedsThreshold = "DRIFT_EXCEEDS_THRESHOLD"
    case driftWithinThreshold = "DRIFT_WITHIN_THRESHOLD"
    case exceedsSingleAssetLimit = "EXCEEDS_SINGLE_ASSET_LIMIT"
}
