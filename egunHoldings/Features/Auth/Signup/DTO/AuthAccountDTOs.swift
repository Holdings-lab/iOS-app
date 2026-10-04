import Foundation

nonisolated struct EmailRequestDTO: Encodable {
    let email: String
}

nonisolated struct EmailVerifyRequestDTO: Encodable {
    let email: String
    let verificationCode: String
}

nonisolated struct AuthRegisterRequestDTO: Encodable {
    let email: String
    let nickname: String
    let password: String
}

nonisolated struct FCMTokenRequestDTO: Encodable {
    let userId: Int64
    let fcmToken: String
}

nonisolated struct NicknameRequestDTO: Encodable {
    let nickname: String
}

nonisolated struct ChangePasswordRequestDTO: Encodable {
    let currentPassword: String
    let newPassword: String
}

nonisolated struct AuthAccountResponseDTO: Decodable {
    let userId: Int64
    let email: String
    let nickname: String

    func toDomain() -> AuthAccountProfile {
        AuthAccountProfile(
            userId: userId,
            email: email,
            nickname: nickname
        )
    }
}
