import Foundation

class RootDetector {
    static func isDeviceJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // 1. Check known jailbreak files/paths
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 2. Check sandboxing isolation by writing to /private
        do {
            let path = "/private/jailbreak_test.txt"
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            // normal sandboxed flow
        }
        
        // 3. Check Cydia protocol scheme handler
        if let url = URL(string: "cydia://package/com.example.test") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        
        return false
        #endif
    }
}
