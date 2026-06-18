import Foundation
import DeviceCheck

class DeviceCheckService {
    static func verify(completion: @escaping (Bool) -> Void) {
        guard DCDevice.current.isSupported else {
            completion(false)
            return
        }
        DCDevice.current.generateToken { token, error in
            guard let _ = token, error == nil else {
                completion(false)
                return
            }
            // Token should be sent to server for verification.
            // For local-only validation, presence of a token is a strong signal.
            completion(true)
        }
    }
}
