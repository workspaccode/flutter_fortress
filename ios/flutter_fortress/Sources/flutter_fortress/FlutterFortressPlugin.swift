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

        registrar.register(SecureViewFactory(messenger: registrar.messenger()), withId: "flutter_fortress/secure_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "checkDeviceIntegrity":
            let isEmulator: Bool = {
                #if targetEnvironment(simulator)
                return true
                #else
                return false
                #endif
            }()
            let status: [String: Any] = [
                "isRooted": RootDetector.isDeviceJailbroken(),
                "isEmulator": isEmulator,
                "isTampered": IntegrityChecker.isAppTampered(),
            ]
            result(status)
        case "setExpectedSignatureHash":
            if let args = call.arguments as? [String: Any],
               let hash = args["hash"] as? String {
                IntegrityChecker.setExpectedHash(hash)
            }
            result(nil)
        case "setScreenSecure":
            if let args = call.arguments as? [String: Any],
               let secure = args["secure"] as? Bool {
                ScreenProtection.setScreenSecure(secure)
            }
            result(nil)
        case "requestDeviceCheck":
            DeviceCheckService.verify { isValid in
                result(isValid)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
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
