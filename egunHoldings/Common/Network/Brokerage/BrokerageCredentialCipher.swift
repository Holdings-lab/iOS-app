import CryptoKit
import Foundation
import Security

nonisolated enum BrokerageCredentialCipherError: Error {
    case keyWrapFailed
}

/// 증권사 크리덴셜 하이브리드 암호화.
/// 크리덴셜 JSON은 일회용 AES-GCM 세션키로 암호화하고, 세션키는 서버 RSA 공개키(OAEP-SHA256)로 감싼다.
nonisolated struct BrokerageCredentialCipher {
    nonisolated struct EncryptedCredential: Sendable {
        let keyId: String
        let encryptedKey: String
        let iv: String
        let ciphertext: String
    }

    private let keyId: String
    private let publicKey: SecKey

    init(keyId: String, publicKey: SecKey) {
        self.keyId = keyId
        self.publicKey = publicKey
    }

    /// Info.plist(`BROKERAGE_SERVER_KEY_ID` / `BROKERAGE_SERVER_PUBLIC_KEY`)의 서버 공개키로 구성한다.
    /// 서버가 아직 공개키를 배포하지 않아 설정이 비어 있으면 nil — 호출부는 로컬 스텁으로 폴백한다.
    static func makeFromConfiguration() -> BrokerageCredentialCipher? {
        guard
            let keyId = NetworkConfiguration.brokerageServerKeyId,
            let base64 = NetworkConfiguration.brokerageServerPublicKeyBase64,
            let publicKey = makePublicKey(base64DER: base64)
        else {
            return nil
        }

        return BrokerageCredentialCipher(keyId: keyId, publicKey: publicKey)
    }

    func encrypt(_ credential: BrokerageCredentialPayloadDTO) throws -> EncryptedCredential {
        let plaintext = try NetworkJSONCoding.encodeJSON(credential)
        let sessionKey = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(plaintext, using: sessionKey)
        let sessionKeyData = sessionKey.withUnsafeBytes { Data($0) }

        var error: Unmanaged<CFError>?
        let wrappedKey = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionOAEPSHA256,
            sessionKeyData as CFData,
            &error
        )

        if let error {
            _ = error.takeRetainedValue()
        }

        guard let wrappedKey else {
            throw BrokerageCredentialCipherError.keyWrapFailed
        }

        return EncryptedCredential(
            keyId: keyId,
            encryptedKey: (wrappedKey as Data).base64EncodedString(),
            iv: Data(sealedBox.nonce).base64EncodedString(),
            // AES-GCM 인증 태그(16바이트)는 암호문 뒤에 이어붙여 전달한다.
            ciphertext: (sealedBox.ciphertext + sealedBox.tag).base64EncodedString()
        )
    }

    /// 서버 키 배포 포맷이 PKCS#1인지 SPKI(X.509)인지 미정이라 둘 다 받아들인다.
    private static func makePublicKey(base64DER: String) -> SecKey? {
        guard let der = Data(base64Encoded: base64DER) else {
            return nil
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]

        if let key = SecKeyCreateWithData(der as CFData, attributes as CFDictionary, nil) {
            return key
        }

        guard let pkcs1 = pkcs1Body(fromSubjectPublicKeyInfo: der) else {
            return nil
        }

        return SecKeyCreateWithData(pkcs1 as CFData, attributes as CFDictionary, nil)
    }

    /// SPKI = SEQUENCE { AlgorithmIdentifier, BIT STRING { PKCS#1 } } 구조에서 PKCS#1 본문만 추출한다.
    private static func pkcs1Body(fromSubjectPublicKeyInfo data: Data) -> Data? {
        var index = data.startIndex

        func readByte() -> UInt8? {
            guard index < data.endIndex else { return nil }
            defer { index = data.index(after: index) }
            return data[index]
        }

        func readLength() -> Int? {
            guard let first = readByte() else { return nil }

            if first < 0x80 {
                return Int(first)
            }

            let byteCount = Int(first & 0x7F)
            guard (1...4).contains(byteCount) else { return nil }

            var length = 0
            for _ in 0..<byteCount {
                guard let byte = readByte() else { return nil }
                length = (length << 8) | Int(byte)
            }
            return length
        }

        guard readByte() == 0x30, readLength() != nil else { return nil }

        guard readByte() == 0x30, let algorithmLength = readLength(),
              let afterAlgorithm = data.index(index, offsetBy: algorithmLength, limitedBy: data.endIndex)
        else { return nil }
        index = afterAlgorithm

        guard readByte() == 0x03, let bitStringLength = readLength(), bitStringLength > 1 else { return nil }
        // BIT STRING 선행 바이트는 unused-bits 개수(공개키에서는 항상 0x00)
        guard readByte() == 0x00 else { return nil }
        guard let end = data.index(index, offsetBy: bitStringLength - 1, limitedBy: data.endIndex) else { return nil }

        return data.subdata(in: index..<end)
    }
}
