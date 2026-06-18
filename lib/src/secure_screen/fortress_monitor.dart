import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../threat_event.dart';
import '../fortress_guard.dart';

class FortressMonitor extends StatefulWidget {
  final Widget child;
  final bool enableInRelease;

  const FortressMonitor({
    super.key,
    required this.child,
    this.enableInRelease = false,
  });

  @override
  State<FortressMonitor> createState() => _FortressMonitorState();
}

class _FortressMonitorState extends State<FortressMonitor> {
  final List<ThreatEvent> _logs = [];
  bool _isExpanded = false;
  late StreamSubscription<ThreatEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FortressGuard().threatStream.listen((event) {
      if (mounted) {
        setState(() {
          _logs.insert(0, event);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode && !widget.enableInRelease) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 80,
          right: 20,
          child: Material(
            type: MaterialType.transparency,
            child: _isExpanded ? _buildDashboard() : _buildFloatingBubble(),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBubble() {
    final hasThreats = _logs.isNotEmpty;
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: hasThreats ? Colors.red.withValues(alpha: 0.9) : Colors.blueGrey.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(
          hasThreats ? Icons.gpp_bad : Icons.gpp_good,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade700, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _logs.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogItem(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(color: Colors.blueGrey.shade800, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Fortress Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
            onPressed: () => setState(() => _isExpanded = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
          SizedBox(height: 12),
          Text(
            'System Secure',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'No threats detected at runtime.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(ThreatEvent log) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.type.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.message,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
