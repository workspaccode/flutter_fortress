import Foundation

class AntiDebug {
    static func isDebuggerAttached() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSysctl() || checkPtraced()
        #endif
    }

    private static func checkSysctl() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    private static func checkPtraced() -> Bool {
        let result = ptrace(PTRACE_TRACEME, 0, 0, 0)
        if result < 0 {
            return true
        }
        ptrace(PTRACE_DETACH, 0, 0, 0)
        return false
    }
}
