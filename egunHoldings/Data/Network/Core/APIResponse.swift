import Foundation

nonisolated struct APIResponse<T: Decodable>: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: T?
}

nonisolated struct EmptyAPIResult: Decodable, Sendable {
    init() {}
}
