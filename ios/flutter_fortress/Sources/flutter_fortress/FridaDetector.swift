import Foundation
import MachO

class FridaDetector {
    static func isFridaDetected() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkFridaPort() || checkLoadedLibraries()
        #endif
    }
    
    private static func checkFridaPort() -> Bool {
        // Run sockets checking internally.
        // For simple offline validation, we scan local loopback ports using standard BSD sockets.
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_addr.s_addr = inet_addr("127.0.0.1")
        
        let ports: [UInt16] = [27042, 27043]
        for port in ports {
            let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
            if socketFileDescriptor >= 0 {
                serverAddress.sin_port = port.bigEndian
                let connectionResult = connect(socketFileDescriptor, {
                    withUnsafePointer(to: &serverAddress) {
                        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
                    }
                }(), socklen_t(MemoryLayout<sockaddr_in>.size))
                
                close(socketFileDescriptor)
                if connectionResult == 0 {
                    return true
                }
            }
        }
        return false
    }
    
    private static func checkLoadedLibraries() -> Bool {
        // Inspect loaded dynamic libraries using dyld API
        let count = _dyld_image_count()
        for i in 0..<count {
            if let rawName = _dyld_get_image_name(i) {
                let name = String(cString: rawName)
                if name.contains("FridaGadget") || name.contains("frida") || name.contains("substrate") {
                    return true
                }
            }
        }
        return false
    }
}
