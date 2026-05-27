import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------------
// WebSocket Message model
// ---------------------------------------------------------------------------

class WsChatMessage {
  final String type; // "message"
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
    required this.time,
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
// WebSocket Service
// ---------------------------------------------------------------------------

class WebSocketService {
  static const String _wsBaseUrl = 'ws://localhost:8080/ws';

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _disposed = false;
  String? _userId;

  // Callback for incoming chat messages
  void Function(WsChatMessage)? onMessage;

  /// Connect to the WebSocket server.
  Future<void> connect(String userId) async {
    _userId = userId;
    _disposed = false;

    final token = ApiService.instance.token;
    final uri = Uri.parse('$_wsBaseUrl?user_id=$userId&token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      // Start ping timer (every 30 seconds)
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _sendJson({'type': 'ping'});
      });

      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final type = json['type'] as String?;
            if (type == 'message') {
              final msg = WsChatMessage.fromJson(json);
              onMessage?.call(msg);
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

  /// Send a chat message via WebSocket (for real-time push).
  void sendMessage(WsChatMessage msg) {
    _sendJson(msg.toJson());
  }

  /// Disconnect and clean up.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

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
