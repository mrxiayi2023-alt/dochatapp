import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import 'call_page.dart';

// ---------------------------------------------------------------------------
// Incoming Call Page — full-screen iOS-style incoming call overlay
// ---------------------------------------------------------------------------

class IncomingCallPage extends StatefulWidget {
  final String callerName;
  final String callerId;
  final String callId;
  final CallType callType;

  const IncomingCallPage({
    super.key,
    required this.callerName,
    required this.callerId,
    required this.callId,
    required this.callType,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    try {
      await ApiService.instance.acceptCall(widget.callId);
    } catch (_) {
      // 即使 API 失败也继续进入通话
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (_) => CallPage(
          name: widget.callerName,
          userId: widget.callerId,
          callType: widget.callType,
          direction: CallDirection.incoming,
          callId: widget.callId,
        ),
      ),
    );
  }

  Future<void> _reject() async {
    try {
      await ApiService.instance.rejectCall(widget.callId);
    } catch (_) {
      // ignore
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callType == CallType.video;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2C2C2E),
                    Color(0xFF1C1C1E),
                    Color(0xFF000000),
                  ],
                ),
              ),
            ),
          ),

          // Caller info
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.callerName.isNotEmpty
                        ? widget.callerName.characters.first
                        : '?',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Call type label
                Text(
                  isVideo ? '邀请你视频通话…' : '邀请你语音通话…',
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),

          // Bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reject
                GestureDetector(
                  onTap: _reject,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.destructiveRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_down_fill,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
                // Accept
                GestureDetector(
                  onTap: _accept,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
