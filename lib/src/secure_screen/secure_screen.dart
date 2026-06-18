import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget wrapper that prevents screenshots and screen recording of its child.
///
/// On Android, this sets `FLAG_SECURE` on the current activity window.
/// On iOS, this uses a native UITextField overlay trick to obscure content
/// during screen captures.
///
/// Wrap sensitive content (e.g. banking info, passwords) with this widget:
/// ```dart
/// SecureScreen(
///   child: MySensitiveWidget(),
/// )
/// ```
class SecureScreen extends StatefulWidget {
  /// The child widget to protect from screenshots/screen recording.
  final Widget child;

  const SecureScreen({
    super.key,
    required this.child,
  });

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('flutter_fortress');
  bool _isSecure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setScreenSecure(true);
  }

  @override
  void dispose() {
    _setScreenSecure(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-apply FLAG_SECURE on Android when app resumes
    if (state == AppLifecycleState.resumed && !_isSecure) {
      _setScreenSecure(true);
    }
  }

  Future<void> _setScreenSecure(bool secure) async {
    try {
      await _channel.invokeMethod('setScreenSecure', {'secure': secure});
      if (mounted) {
        setState(() => _isSecure = secure);
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to set screen secure state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
