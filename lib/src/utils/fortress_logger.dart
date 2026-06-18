import 'dart:developer' as developer;

class FortressLogger {
  static bool enabled = true;

  static void info(String message) {
    if (!enabled) return;
    developer.log('🛡️ [Fortress - INFO] $message');
  }

  static void warn(String message) {
    if (!enabled) return;
    developer.log('⚠️ [Fortress - WARN] $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!enabled) return;
    developer.log('🚨 [Fortress - ERROR] $message', error: error, stackTrace: stackTrace);
  }
}
