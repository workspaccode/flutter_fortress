import Flutter
import UIKit

public class FlutterFortressPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var timer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_fortress", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_fortress_events", binaryMessenger: registrar.messenger())
        
        let instance = FlutterFortressPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        
        // Register the SecureNativeView platform view
        registrar.register(SecureViewFactory(messenger: registrar.messenger()), withId: "flutter_fortress/secure_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "checkDeviceIntegrity":
            #if targetEnvironment(simulator)
            let isEmulator = true
            #else
            let isEmulator = false
            #endif
            
            let status: [String: Any] = [
                "isRooted": RootDetector.isDeviceJailbroken(),
                "isEmulator": isEmulator,
                "isTampered": false // Basic bundle identifier checks can be hooked up if expected details passed
            ]
            result(status)
        case "setScreenSecure":
            if let args = call.arguments as? [String: Any],
               let secure = args["secure"] as? Bool {
                ScreenProtection.setScreenSecure(secure)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // StreamHandler implementation
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Setup screen capture observation notifications
        NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
        
        // Periodic check for Frida
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(periodicSecurityChecks), userInfo: nil, repeats: true)
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        timer?.invalidate()
        timer = nil
        return nil
    }
    
    @objc private func screenCaptureChanged() {
        if ScreenProtection.isScreenRecording() {
            sendThreatEvent(type: "screenCapture", message: "Screen recording capture detected.")
        }
    }
    
    @objc private func periodicSecurityChecks() {
        if FridaDetector.isFridaDetected() {
            sendThreatEvent(type: "hooking", message: "Frida hook framework injection detected.")
        }
    }
    
    private func sendThreatEvent(type: String, message: String) {
        DispatchQueue.main.async {
            self.eventSink?([
                "type": type,
                "message": message,
                "details": [:]
            ])
        }
    }
}
