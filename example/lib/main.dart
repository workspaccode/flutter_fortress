import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortress/flutter_fortress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final threatLog = <ThreatEvent>[];

  await FortressGuard.init(
    policy: const FortressPolicy(
      onRootDetected: ThreatResponse.kill,
      onHookingDetected: ThreatResponse.kill,
      onEmulatorDetected: ThreatResponse.warn,
      onSSLPinFail: ThreatResponse.kill,
      onScreenCapture: ThreatResponse.log,
      onTamperDetected: ThreatResponse.kill,
    ),
    onThreat: (event) {
      debugPrint('Threat: ${event.type.name} | ${event.message}');
      threatLog.insert(0, event);
    },
  );

  runApp(FortressExampleApp(threatLog: threatLog));
}

class FortressExampleApp extends StatelessWidget {
  final List<ThreatEvent> threatLog;

  const FortressExampleApp({super.key, required this.threatLog});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Fortress Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E293B),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: FortressMonitor(
        child: HomeScreen(threatLog: threatLog),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<ThreatEvent> threatLog;

  const HomeScreen({super.key, required this.threatLog});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DeviceIntegrityStatus? _integrityStatus;
  bool _isLoading = false;
  late StreamSubscription<ThreatEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FortressGuard().threatStream.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkIntegrity() async {
    setState(() => _isLoading = true);
    final status = await FortressGuard.checkDeviceIntegrity();
    setState(() {
      _integrityStatus = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Fortress Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ThreatLogScreen(threatLog: widget.threatLog),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntegrityCard(),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.lock_outline,
              title: 'SSL Pinning',
              description: 'Public Key Hash pinning via Dio interceptor.',
              child: _buildSSLPinningDemo(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.phone_android,
              title: 'Root / Jailbreak Detection',
              description: 'Scans binaries, system props, and sandbox integrity.',
              child: _buildRootDetectionDemo(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.bug_report_outlined,
              title: 'Anti-Frida & Hooking',
              description: 'Port scanning + /proc/self/maps + dyld inspection.',
              child: _buildFridaDetectionDemo(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.screenshot_outlined,
              title: 'Anti-Screenshot & Recording',
              description: 'FLAG_SECURE (Android) / UITextField overlay (iOS).',
              child: _buildScreenProtectionDemo(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.verified_outlined,
              title: 'App Integrity & Tamper Detection',
              description: 'Runtime APK/IPA signature hash verification.',
              child: _buildTamperDetectionDemo(),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.monitor_outlined,
              title: 'Fortress Monitor',
              description: 'Real-time threat status dashboard overlay.',
              child: _buildMonitorDemo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Integrity Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_integrityStatus != null) ...[
              _buildStatusRow('Rooted', _integrityStatus!.isRooted),
              _buildStatusRow('Emulator', _integrityStatus!.isEmulator),
              _buildStatusRow('Tampered', _integrityStatus!.isTampered),
              const Divider(height: 24),
              _buildStatusRow('Trusted', _integrityStatus!.isTrusted),
            ] else
              const Text(
                'Tap the button below to check device integrity.',
                style: TextStyle(color: Colors.white54),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _checkIntegrity,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.security),
              label: Text(_isLoading ? 'Checking...' : 'Check Integrity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isCompromised) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isCompromised ? Icons.cancel : Icons.check_circle,
            color: isCompromised ? Colors.redAccent : Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSSLPinningDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FortressHttpClient wraps Dio with SPKI pinning:',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'final client = FortressHttpClient.create(\n'
            "  pinnedKeys: ['sha256/AAAA...=='],\n"
            ');',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRootDetectionDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Checks for su binaries, Magisk, root apps, build tags, and /system write access.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'final status = await FortressGuard.checkDeviceIntegrity();\n'
            'if (!status.isTrusted) FortressGuard.kill();',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFridaDetectionDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Periodically scans ports 27042/27043, /proc/self/maps, and loaded dylibs.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '// Runs automatically in background via EventChannel\n'
            '// Fires ThreatEvent.hooking if Frida detected',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenProtectionDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wrap sensitive screens to block screenshots and recording:',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'SecureScreen(\n'
            '  child: MySensitiveWidget(),\n'
            ')',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTamperDetectionDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verifies APK/IPA signature hash against expected value:',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '// Set expected hash at build time\n'
            '// IntegrityChecker.isAppTampered() checks at runtime',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonitorDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Floating bubble overlay showing real-time threat status. Tap the shield icon in the app bar to see the threat log.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              FortressGuard().threatStream.isBroadcast ? Icons.circle : Icons.circle_outlined,
              color: FortressGuard().threatStream.isBroadcast ? Colors.greenAccent : Colors.white38,
              size: 12,
            ),
            const SizedBox(width: 8),
            Text(
              FortressGuard().threatStream.isBroadcast ? 'Monitor active' : 'Monitor idle',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class ThreatLogScreen extends StatelessWidget {
  final List<ThreatEvent> threatLog;

  const ThreatLogScreen({super.key, required this.threatLog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threat Log'),
        actions: [
          if (threatLog.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                threatLog.clear();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: threatLog.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No threats detected',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'System is secure. No security events recorded.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threatLog.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = threatLog[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      _getThreatIcon(event.type),
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      event.type.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(event.message),
                    trailing: Text(
                      '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getThreatIcon(ThreatType type) {
    switch (type) {
      case ThreatType.root:
      case ThreatType.jailbreak:
        return Icons.phone_android;
      case ThreatType.emulator:
        return Icons.computer;
      case ThreatType.hooking:
        return Icons.bug_report;
      case ThreatType.sslPinningMismatch:
        return Icons.wifi_off;
      case ThreatType.screenCapture:
        return Icons.screenshot;
      case ThreatType.tamper:
        return Icons.gpp_bad;
    }
  }
}
