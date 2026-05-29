import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------------
// WebSocket Message model
// ---------------------------------------------------------------------------

class WsChatMessage {
  final String type;
  final String fromId;
  final String? toId;
  final String content;
  final String time;
  final String? msgId;

  WsChatMessage({
    required this.type,
    required this.fromId,
    this.toId,
    required this.content,
    this.time = '',
    this.msgId,
  });

  factory WsChatMessage.fromJson(Map<String, dynamic> json) {
    return WsChatMessage(
      type: json['type'] as String? ?? 'message',
      fromId: json['from_id'] as String? ?? '',
      toId: json['to_id'] as String?,
      content: json['content'] as String? ?? '',
      time: json['time'] as String? ?? '',
      msgId: json['msg_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'from_id': fromId,
        if (toId != null) 'to_id': toId,
        'content': content,
        'time': time,
        if (msgId != null) 'msg_id': msgId,
      };
}

// ---------------------------------------------------------------------------
// WebSocket Service — singleton, single connection, multicast listeners
// ---------------------------------------------------------------------------

/// Singleton WebSocket service. 全局唯一连接，多播分发消息。
/// 各处通过 [WebSocketService.shared] 获取同一实例，然后 addListener / removeListener。
class WebSocketService {
  static const String _wsBaseUrl = 'ws://localhost:8080/ws';

  // ---- Singleton ----
  static final WebSocketService _instance = WebSocketService._internal();
  static WebSocketService get shared => _instance;
  WebSocketService._internal();

  // ---- Connection state ----
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _disposed = false;
  String? _userId;

  /// 多播侦听器：type → [listener, ...]
  final Map<String, List<void Function(WsChatMessage)>> _listeners = {};

  /// 注册一个指定消息类型的侦听器
  void addListener(String type, void Function(WsChatMessage) cb) {
    _listeners.putIfAbsent(type, () => []).add(cb);
  }

  /// 移除一个侦听器
  void removeListener(String type, void Function(WsChatMessage) cb) {
    _listeners[type]?.remove(cb);
  }

  // ---- Convenience helpers for common types ----
  void onMessage(void Function(WsChatMessage) cb) => addListener('message', cb);
  void offMessage(void Function(WsChatMessage) cb) => removeListener('message', cb);
  void onCallStart(void Function(WsChatMessage) cb) => addListener('call-start', cb);
  void offCallStart(void Function(WsChatMessage) cb) => removeListener('call-start', cb);
  void onCallAccept(void Function(WsChatMessage) cb) => addListener('call-accept', cb);
  void offCallAccept(void Function(WsChatMessage) cb) => removeListener('call-accept', cb);
  void onCallReject(void Function(WsChatMessage) cb) => addListener('call-reject', cb);
  void offCallReject(void Function(WsChatMessage) cb) => removeListener('call-reject', cb);
  void onCallEnd(void Function(WsChatMessage) cb) => addListener('call-end', cb);
  void offCallEnd(void Function(WsChatMessage) cb) => removeListener('call-end', cb);
  void onOffer(void Function(WsChatMessage) cb) => addListener('offer', cb);
  void offOffer(void Function(WsChatMessage) cb) => removeListener('offer', cb);
  void onAnswer(void Function(WsChatMessage) cb) => addListener('answer', cb);
  void offAnswer(void Function(WsChatMessage) cb) => removeListener('answer', cb);
  void onIceCandidate(void Function(WsChatMessage) cb) => addListener('ice-candidate', cb);
  void offIceCandidate(void Function(WsChatMessage) cb) => removeListener('ice-candidate', cb);

  /// 连接（若已连接同一用户则忽略）
  Future<void> connect(String userId) async {
    if (_channel != null && _userId == userId) return;

    _userId = userId;
    _disposed = false;

    final token = ApiService.instance.token;
    final uri = Uri.parse('$_wsBaseUrl?user_id=$userId&token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _sendJson({'type': 'ping'});
      });

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final type = json['type'] as String? ?? '';
            final msg = WsChatMessage.fromJson(json);
            // 多播：通知所有该类型的侦听器
            final cbs = _listeners[type] ?? [];
            for (final cb in List.from(cbs)) {
              cb(msg);
            }
          } catch (_) {
            // Ignore malformed messages
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket closed');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('WebSocket connect failed: $e');
      _scheduleReconnect();
    }
  }

  /// 发送聊天消息
  void sendMessage(WsChatMessage msg) {
    _sendJson(msg.toJson());
  }

  /// 发送 WebRTC 信令
  void sendSignaling(String toId, String type, String content) {
    _sendJson({
      'type': type,
      'to_id': toId,
      'content': content,
    });
  }

  /// 断开连接并清理
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _listeners.clear();
  }

  void _sendJson(Map<String, dynamic> json) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(json));
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed && _userId != null) {
        connect(_userId!);
      }
    });
  }
}

