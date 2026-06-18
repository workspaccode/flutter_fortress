import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'threat_event.dart';
import 'fortress_policy.dart';
import 'utils/fortress_logger.dart';

class FortressGuard {
  static const MethodChannel _methodChannel = MethodChannel('flutter_fortress');
  static const EventChannel _eventChannel = EventChannel('flutter_fortress_events');

  static final FortressGuard _instance = FortressGuard._internal();
  factory FortressGuard() => _instance;
  FortressGuard._internal();

  FortressPolicy _policy = const FortressPolicy();
  Function(ThreatEvent)? _onThreatCallback;
  final StreamController<ThreatEvent> _threatController = StreamController<ThreatEvent>.broadcast();

  Stream<ThreatEvent> get threatStream => _threatController.stream;

  static Future<void> init({
    required FortressPolicy policy,
    Function(ThreatEvent)? onThreat,
  }) async {
    _instance._policy = policy;
    _instance._onThreatCallback = onThreat;
    _instance._startListening();
    FortressLogger.info('FortressGuard initialized.');
    
    // Proactively check device integrity at startup
    await checkDeviceIntegrity();
  }

  void _startListening() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final typeStr = event['type'] as String;
          final message = event['message'] as String? ?? 'Security threat triggered';
          final details = Map<String, dynamic>.from(event['details'] as Map? ?? {});

          ThreatType? type;
          for (final t in ThreatType.values) {
            if (t.name == typeStr) {
              type = t;
              break;
            }
          }

          if (type != null) {
            final threatEvent = ThreatEvent(
              type: type,
              message: message,
              details: details,
            );
            handleThreat(threatEvent);
          }
        }
      },
      onError: (dynamic error) {
        FortressLogger.error('Error in threat event stream', error);
      },
    );
  }

  /// Manually checks root, jailbreak, emulator status, or signature integrity
  static Future<DeviceIntegrityStatus> checkDeviceIntegrity() async {
    try {
      final Map? status = await _methodChannel.invokeMethod('checkDeviceIntegrity');
      if (status != null) {
        final isRooted = status['isRooted'] as bool? ?? false;
        final isEmulator = status['isEmulator'] as bool? ?? false;
        final isTampered = status['isTampered'] as bool? ?? false;

        if (isRooted) {
          _instance.handleThreat(ThreatEvent(
            type: Platform.isAndroid ? ThreatType.root : ThreatType.jailbreak,
            message: 'Device security check failed: Root/Jailbreak detected.',
          ));
        }
        if (isEmulator) {
          _instance.handleThreat(ThreatEvent(
            type: ThreatType.emulator,
            message: 'Device security check failed: Emulator environment detected.',
          ));
        }
        if (isTampered) {
          _instance.handleThreat(ThreatEvent(
            type: ThreatType.tamper,
            message: 'Device security check failed: App signature tamper detected.',
          ));
        }

        return DeviceIntegrityStatus(
          isRooted: isRooted,
          isEmulator: isEmulator,
          isTampered: isTampered,
        );
      }
    } on PlatformException catch (e) {
      FortressLogger.error('Failed checking device integrity', e);
    }
    return const DeviceIntegrityStatus(isRooted: false, isEmulator: false, isTampered: false);
  }

  /// Processes threat event according to active policy
  void handleThreat(ThreatEvent event) {
    FortressLogger.warn('Security threat triggered: ${event.type.name} - ${event.message}');
    _threatController.add(event);
    _onThreatCallback?.call(event);

    final response = _policy.getResponseFor(event.type);
    if (response == ThreatResponse.kill) {
      FortressLogger.error('Threat policy dictates termination. Killing application.');
      kill();
    }
  }

  /// Wipes active context details and closes the process
  static void kill() {
    // Graceful exit triggers
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    // Hard exit fallback
    Future.delayed(const Duration(milliseconds: 200), () {
      exit(0);
    });
  }
}

class DeviceIntegrityStatus {
  final bool isRooted;
  final bool isEmulator;
  final bool isTampered;

  const DeviceIntegrityStatus({
    required this.isRooted,
    required this.isEmulator,
    required this.isTampered,
  });

  bool get isTrusted => !isRooted && !isEmulator && !isTampered;
}
