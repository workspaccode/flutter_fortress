import UIKit
import Flutter

class ScreenProtection {
    private static var secureTextField: UITextField?
    
    static func configureSecureView(for window: UIWindow?) {
        guard let window = window else { return }
        
        // Use iOS UITextField custom password input mechanism to obscure window content during screenshots
        let textField = UITextField()
        textField.isSecureTextEntry = true
        
        if let secureContainer = textField.subviews.first {
            // Reparent the window content into the secure container's view
            secureContainer.frame = window.bounds
            
            // Set up secure overlay
            window.addSubview(secureContainer)
            secureContainer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                secureContainer.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                secureContainer.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                secureContainer.topAnchor.constraint(equalTo: window.topAnchor),
                secureContainer.bottomAnchor.constraint(equalTo: window.bottomAnchor)
            ])
            
            self.secureTextField = textField
        }
    }
    
    static func setScreenSecure(_ secure: Bool) {
        DispatchQueue.main.async {
            guard let app = UIApplication.shared.delegate,
                  let window = app.window else { return }
            
            if secure {
                // Attach overlay if not already attached
                if secureTextField == nil {
                    configureSecureView(for: window)
                }
            } else {
                // Find and remove secure subviews
                if let subviews = window?.subviews {
                    for subview in subviews {
                        if subview.description.contains("LayoutContainer") || subview.description.contains("Canvas") {
                            // UITextField subview container removal
                            subview.removeFromSuperview()
                        }
                    }
                }
                secureTextField = nil
            }
        }
    }
    
    static func isScreenRecording() -> Bool {
        return UIScreen.main.isCaptured
    }
}

class SecureViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return SecureNativeView(frame: frame, viewId: viewId, messenger: messenger)
    }
}

class SecureNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView
    
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        // Embed secure text field layout natively
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        
        _view = secureField.subviews.first ?? UIView(frame: frame)
        _view.backgroundColor = .clear
        
        super.init()
    }
    
    func view() -> UIView {
        return _view
    }
}
