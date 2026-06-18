import Foundation
import CommonCrypto

class IntegrityChecker {
    private static var expectedHash: String?

    static func setExpectedHash(_ hash: String) {
        expectedHash = hash
    }

    static func isAppTampered() -> Bool {
        guard let expected = expectedHash, !expected.isEmpty else {
            return false
        }
        guard let executableURL = Bundle.main.executableURL,
              let fileHandle = try? FileHandle(forReadingFrom: executableURL) else {
            return true
        }
        defer { try? fileHandle.close() }
        let data = fileHandle.readDataToEndOfFile()
        let currentHash = sha256Base64(data)
        return currentHash != expected
    }

    private static func sha256Base64(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
}
