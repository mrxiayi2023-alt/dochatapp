// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：音视频通话页面

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

// ---------------------------------------------------------------------------
// Call Type
// ---------------------------------------------------------------------------

enum CallType { audio, video }

// ---------------------------------------------------------------------------
// Call Direction
// ---------------------------------------------------------------------------

enum CallDirection { outgoing, incoming }

// ---------------------------------------------------------------------------
// Call Page
// ---------------------------------------------------------------------------

/// 音视频通话页面，支持WebRTC通话
class CallPage extends StatefulWidget {
  final String name;
  final String? userId;     // 对方用户ID
  final CallType callType;
  final CallDirection direction;
  final String? callId;     // 呼叫ID（由API返回或从WebSocket获得）

  const CallPage({
    super.key,
    required this.name,
    this.userId,
    required this.callType,
    this.direction = CallDirection.outgoing,
    this.callId,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

/// CallPage的状态管理
class _CallPageState extends State<CallPage> {
  // Timer
  int _seconds = 0;
  Timer? _timer;
  bool _connected = false;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Toggle states
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOn = true;

  // ICE servers
  static const List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];

  /// 时间戳日志辅助方法，用于定位WebRTC延迟瓶颈
  void _log(String event) {
    final ts = DateTime.now();
    final fmt = '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}.'
        '${ts.millisecond.toString().padLeft(3, '0')}';
    debugPrint('[WebRTC][$fmt] $event');
  }

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  /// 初始化通话，启动摄像头和WebSocket信令
  void initState() {
    super.initState();
    // 接收方：用户已在 IncomingCallPage 中点击接听，通话管理状态即为"已接通"
    // 发起方：需等待对方接听后通过 _onCallAccepted 设为 true
    if (widget.direction == CallDirection.incoming) {
      _connected = true;
    }
    _initRenderers();
    // 先获取本地媒体流，完成后立即预创建 PeerConnection，
    // 这样当 offer/answer 信令到达时 PC 已就绪，省去 300-500ms 初始化时间。
    _startLocalStream().then((_) {
      _createPeerConnection();
    });
    _connectWebSocket();
    // 接收方：在进入 CallPage 时（用户刚按接听）开始计时
    // 发起方：在 _onCallAccepted 收到对方接听通知后才开始计时
    if (widget.direction == CallDirection.incoming) {
      _startTimer();
    }
  }

  @override
  /// 释放摄像头、WebRTC连接和WebSocket监听
  void dispose() {
    _timer?.cancel();
    // Don't dispose the shared WebSocket — other pages depend on it
    WebSocketService.shared.offOffer(_onOfferReceived);
    WebSocketService.shared.offAnswer(_onAnswerReceived);
    WebSocketService.shared.offIceCandidate(_onIceCandidateReceived);
    WebSocketService.shared.offCallAccept(_onCallAccepted);
    WebSocketService.shared.offCallReject(_onCallRejected);
    WebSocketService.shared.offCallEnd(_onCallEndReceived);
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  /// 初始化本地和远端视频渲染器
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  /// 启动本地摄像头/麦克风流
  Future<void> _startLocalStream() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': widget.callType == CallType.video
          ? <String, dynamic>{
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      if (mounted) setState(() {});
    } catch (e) {
// print('getUserMedia error: $e');  // FIXED: removed print statement
    }
  }

  /// 注册WebRTC信令回调
  Future<void> _connectWebSocket() async {
    // Register signaling callbacks (shared global instance handles connection)
    WebSocketService.shared.onOffer(_onOfferReceived);
    WebSocketService.shared.onAnswer(_onAnswerReceived);
    WebSocketService.shared.onIceCandidate(_onIceCandidateReceived);
    WebSocketService.shared.onCallEnd(_onCallEndReceived);

    if (widget.direction == CallDirection.outgoing) {
      // 发起方：等待call-accept信令后创建offer
      WebSocketService.shared.onCallAccept(_onCallAccepted);
      WebSocketService.shared.onCallReject(_onCallRejected);
    }
  }

  /// 处理对方接听事件
  void _onCallAccepted(WsChatMessage msg) {
    if (widget.callId != null && msg.msgId == widget.callId) {
      setState(() => _connected = true);
      // 发起方在对方接听后才开始计时，与接收方同步
      if (_timer == null) {
        _startTimer();
      }
      _createOffer();
    }
  }

  /// 处理对方拒绝事件
  void _onCallRejected(WsChatMessage msg) {
    if (widget.callId != null && msg.msgId == widget.callId) {
      _showToast('对方拒绝了通话');
      Navigator.of(context).pop();
    }
  }

  /// 处理对方挂断事件（WebSocket call-end 消息）
  void _onCallEndReceived(WsChatMessage msg) {
    if (widget.callId != null && widget.callId!.isNotEmpty && msg.msgId == widget.callId) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// 启动通话计时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  /// 格式化通话时长
  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -----------------------------------------------------------------------
  // WebRTC PeerConnection
  // -----------------------------------------------------------------------

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    _log('_createPeerConnection start');
    try {
      _peerConnection = await createPeerConnection({
        'iceServers': _iceServers,
      }, {
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      });

      // Add local tracks
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await _peerConnection!.addTrack(track, _localStream!);
        }
      }

      // ICE candidate handler
      _peerConnection!.onIceCandidate = (candidate) {
        final json = jsonEncode(candidate.toMap());
        _log('local ICE candidate → ${widget.userId}');
        WebSocketService.shared.sendSignaling(
          widget.userId ?? '',
          'ice-candidate',
          json,
        );
      };

      // Remote stream handler
      _peerConnection!.onTrack = (event) {
        _log('remote track received: kind=${event.track.kind}');
        if (event.track.kind == 'video' || event.track.kind == 'audio') {
          _remoteRenderer.srcObject = event.streams[0];
          if (mounted) setState(() {});
        }
      };

      // Connection state handler
      _peerConnection!.onConnectionState = (state) {
        final stateStr = state.toString();
        _log('connection state → $stateStr');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _hangUp();
        }
      };
      _log('_createPeerConnection done');
    } catch (e) {
      _log('_createPeerConnection error: $e');
    }
  }

  /// 创建WebRTC Offer
  Future<void> _createOffer() async {
    _log('_createOffer start');
    // _createPeerConnection may already be done (pre-created in initState)
    await _createPeerConnection();
    if (_peerConnection == null) {
      _log('_createOffer: no PeerConnection');
      return;
    }

    try {
      final offer = await _peerConnection!.createOffer();
      _log('createOffer done');
      await _peerConnection!.setLocalDescription(offer);
      _log('setLocalDescription (offer) done');
      final json = jsonEncode(offer.toMap());
      WebSocketService.shared.sendSignaling(widget.userId ?? '', 'offer', json);
      _log('offer sent to ${widget.userId}');
    } catch (e) {
      _log('createOffer error: $e');
    }
  }

  /// 处理收到的Offer
  Future<void> _onOfferReceived(WsChatMessage msg) async {
    if (widget.userId != null && msg.fromId != widget.userId) return;
    _log('offer received from ${msg.fromId}');
    // _createPeerConnection may already be done (pre-created in initState);
    // the guard inside ensures it's only created once.
    await _createPeerConnection();
    if (_peerConnection == null) {
      _log('offer dropped: no PeerConnection');
      return;
    }

    try {
      final map = jsonDecode(msg.content) as Map<String, dynamic>;
      final desc = RTCSessionDescription(
        map['sdp'] as String? ?? '',
        map['type'] as String? ?? '',
      );
      await _peerConnection!.setRemoteDescription(desc);
      _log('setRemoteDescription done');
      final answer = await _peerConnection!.createAnswer();
      _log('createAnswer done');
      await _peerConnection!.setLocalDescription(answer);
      _log('setLocalDescription done');
      final json = jsonEncode(answer.toMap());
      WebSocketService.shared.sendSignaling(widget.userId ?? '', 'answer', json);
      _log('answer sent to ${widget.userId}');
      if (mounted) setState(() => _connected = true);
    } catch (e) {
      _log('handleOffer error: $e');
    }
  }

  /// 处理收到的Answer
  Future<void> _onAnswerReceived(WsChatMessage msg) async {
    if (widget.userId != null && msg.fromId != widget.userId) return;
    if (_peerConnection == null) return;
    _log('answer received from ${msg.fromId}');

    try {
      final map = jsonDecode(msg.content) as Map<String, dynamic>;
      final desc = RTCSessionDescription(
        map['sdp'] as String? ?? '',
        map['type'] as String? ?? '',
      );
      await _peerConnection!.setRemoteDescription(desc);
      _log('setRemoteDescription (answer) done');
    } catch (e) {
      _log('handleAnswer error: $e');
    }
  }

  /// 处理ICE候选者
  Future<void> _onIceCandidateReceived(WsChatMessage msg) async {
    if (widget.userId != null && msg.fromId != widget.userId) return;
    if (_peerConnection == null) return;

    try {
      final candidateMap = jsonDecode(msg.content) as Map<String, dynamic>;
      final candidate = RTCIceCandidate(
        candidateMap['candidate'] as String,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int? ?? 0,
      );
      await _peerConnection!.addCandidate(candidate);
      _log('remote ICE candidate added');
    } catch (e) {
      _log('addIceCandidate error: $e');
    }
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------

  /// 挂断通话
  void _hangUp() {
    // Notify backend
    if (widget.callId != null && widget.callId!.isNotEmpty) {
      ApiService.instance.endCall(widget.callId!).then((_) {}, onError: (_) {});
    }
    Navigator.of(context).pop();
  }

  /// 切换麦克风静音
  void _toggleMute() => setState(() {
        _isMuted = !_isMuted;
        _localStream?.getAudioTracks().forEach((t) {
          t.enabled = !_isMuted;
        });
      });

  /// 切换扬声器
  void _toggleSpeaker() => setState(() => _isSpeakerOn = !_isSpeakerOn);

  /// 切换摄像头
  void _toggleCamera() => setState(() {
        _isCameraOn = !_isCameraOn;
        _localStream?.getVideoTracks().forEach((t) {
          t.enabled = _isCameraOn;
        });
      });

  void _showToast(String msg) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  /// 构建通话页面UI
  Widget build(BuildContext context) {
    final isVideo = widget.callType == CallType.video;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: Stack(
        children: [
          // --- Main area: remote video or voice avatar ---
          if (isVideo && _remoteRenderer.srcObject != null)
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            Positioned.fill(
              child: _buildVoiceAvatar(),
            ),

          // --- Self preview (video only, picture-in-picture) ---
          if (isVideo && _localStream != null)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: RTCVideoView(
                    _localRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: true,
                  ),
                ),
              ),
            ),

          // --- Top overlay ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _connected ? _formatTime(_seconds) : _statusText(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // --- Bottom controls ---
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 40,
            child: _buildControls(isVideo),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    if (widget.direction == CallDirection.outgoing) {
      return '正在呼叫…';
    } else {
      return '呼入中…';
    }
  }

  // -----------------------------------------------------------------------
  // Voice avatar with ripple
  // -----------------------------------------------------------------------

  /// 构建语音通话头像（带波纹动画）
  Widget _buildVoiceAvatar() {
    final color = CupertinoColors.activeBlue;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ripple animation
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _pulseCircle(color.withValues(alpha: 0.3), 140),
                _pulseCircle(color.withValues(alpha: 0.2), 110),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.name.isNotEmpty ? widget.name[0] : '?',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _connected ? '语音通话中…' : '等待对方接听…',
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseCircle(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Bottom control bar
  // -----------------------------------------------------------------------

  /// 构建底部控制栏
  Widget _buildControls(bool isVideo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute
        _ControlButton(
          icon: _isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill,
          label: _isMuted ? '静音' : '麦克风',
          isActive: !_isMuted,
          onTap: _toggleMute,
        ),
        const SizedBox(width: 32),
        // Hangup
        GestureDetector(
          onTap: _hangUp,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: CupertinoColors.destructiveRed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.phone_down_fill,
              color: CupertinoColors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Speaker
        _ControlButton(
          icon: _isSpeakerOn ? CupertinoIcons.speaker_3_fill : CupertinoIcons.speaker_slash_fill,
          label: _isSpeakerOn ? '扬声器' : '听筒',
          isActive: _isSpeakerOn,
          onTap: _toggleSpeaker,
        ),
        if (isVideo) ...[
          const SizedBox(width: 32),
          // Camera toggle
          _ControlButton(
            icon: _isCameraOn ? CupertinoIcons.videocam_fill : CupertinoIcons.videocam,
            label: _isCameraOn ? '摄像头' : '关闭',
            isActive: _isCameraOn,
            onTap: _toggleCamera,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Control Button
// ---------------------------------------------------------------------------

/// 通话控制按钮组件
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  /// 构建通话页面UI
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? CupertinoColors.white.withValues(alpha: 0.2)
                  : CupertinoColors.destructiveRed.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? CupertinoColors.white : CupertinoColors.systemGrey,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? CupertinoColors.white : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
