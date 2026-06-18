import Foundation
import MachO

class FridaDetector {
    private static let suspiciousPorts: [UInt16] = [27042, 27043, 27044, 27045, 20242]

    static func isFridaDetected() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkFridaPort() || checkLoadedLibraries()
        #endif
    }

    private static func checkFridaPort() -> Bool {
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_addr.s_addr = inet_addr("127.0.0.1")

        for port in suspiciousPorts {
            let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
            if socketFileDescriptor >= 0 {
                serverAddress.sin_port = port.bigEndian
                var addr = serverAddress
                let connectionResult = withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                        connect(socketFileDescriptor, ptr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                close(socketFileDescriptor)
                if connectionResult == 0 {
                    return true
                }
            }
        }
        return false
    }

    private static func checkLoadedLibraries() -> Bool {
        let count = _dyld_image_count()
        for i in 0..<count {
            if let rawName = _dyld_get_image_name(i) {
                let name = String(cString: rawName)
                if name.contains("FridaGadget") ||
                    name.contains("frida") ||
                    name.contains("substrate") ||
                    name.contains("gadget") ||
                    name.contains("cycript") {
                    return true
                }
            }
        }
        return false
    }
}
