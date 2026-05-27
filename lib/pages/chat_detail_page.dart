import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/websocket_service.dart';
import 'call_page.dart';

// ---------------------------------------------------------------------------
// Message Model (UI)
// ---------------------------------------------------------------------------

class Message {
  final String id;
  final String text;
  final bool isMe;
  final String time; // "HH:mm"
  final String fromId;

  Message({
    String? id,
    required this.text,
    required this.isMe,
    required this.time,
    this.fromId = '',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

// ---------------------------------------------------------------------------
// Chat Detail Page
// ---------------------------------------------------------------------------

class ChatDetailPage extends ConsumerStatefulWidget {
  final ChatModel chat;
  final String? targetUserId; // backend user ID for API calls

  const ChatDetailPage({super.key, required this.chat, this.targetUserId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final WebSocketService _wsService = WebSocketService();
  bool _loadingHistory = true;
  bool _useDemoFallback = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _wsService.onMessage = null;
    super.dispose();
  }

  Future<void> _initChat() async {
    // Connect WebSocket
    final authState = ref.read(authProvider);
    final myId = authState.user?['id'] as String?;
    if (myId != null) {
      _wsService.onMessage = _onWsMessage;
      await _wsService.connect(myId);
    }

    // Load chat history from API
    await _loadHistory();

    if (mounted) {
      setState(() => _loadingHistory = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _loadHistory() async {
    final otherId = widget.targetUserId;
    if (otherId == null || otherId.isEmpty) {
      _fallbackToDemo();
      return;
    }

    try {
      final data = await ApiService.instance.getChatHistory(otherId);
      final authState = ref.read(authProvider);
      final myId = authState.user?['id'] as String? ?? '';

      final messages = data.map((m) {
        final fromId = m['from_id'] as String? ?? '';
        return Message(
          id: m['id'] as String? ?? '',
          text: m['content'] as String? ?? '',
          isMe: fromId == myId,
          time: _formatApiTime(m['created_at'] as String?),
          fromId: fromId,
        );
      }).toList();

      if (mounted) setState(() => _messages.addAll(messages));
      return;
    } catch (_) {
      // API failed, fall back to demo
    }

    _fallbackToDemo();
  }

  void _fallbackToDemo() {
    _useDemoFallback = true;
    final demoMessages = [
      Message(text: '你好，周末有空吗？', isMe: false, time: '14:30'),
      Message(text: '有空啊，怎么了？', isMe: true, time: '14:32'),
      Message(text: '周末一起去杭州西湖旅游吧？', isMe: false, time: '14:33'),
      Message(text: '好啊！我早就想去了', isMe: true, time: '14:33'),
      Message(text: '我查了攻略，可以坐船游湖，还能去灵隐寺', isMe: false, time: '14:35'),
      Message(text: '太棒了，那我订酒店', isMe: true, time: '14:36'),
      Message(text: 'ok，到时候见👋', isMe: false, time: '14:37'),
    ];
    if (mounted) setState(() => _messages.addAll(demoMessages));
  }

  String _formatApiTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// Handle incoming WebSocket message.
  void _onWsMessage(WsChatMessage wsMsg) {
    if (!mounted) return;
    final otherId = widget.targetUserId;
    // Only show messages from the current chat partner
    if (otherId != null && wsMsg.fromId != otherId) return;

    setState(() {
      _messages.add(Message(
        id: wsMsg.msgId ?? '',
        text: wsMsg.content,
        isMe: false,
        time: wsMsg.time,
        fromId: wsMsg.fromId,
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final msg = Message(text: text, isMe: true, time: timeStr);

    setState(() {
      _messages.add(msg);
      _textController.clear();
    });

    _scrollToBottom();

    // Try to send via API
    final otherId = widget.targetUserId;
    if (otherId != null && !_useDemoFallback) {
      try {
        await ApiService.instance.sendMessage(toId: otherId, content: text);
      } catch (_) {
        // Silent fail — message still shows locally
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _timeDiffInMinutes(String t1, String t2) {
    try {
      final p1 = t1.split(':');
      final p2 = t2.split(':');
      return (int.parse(p2[0]) * 60 + int.parse(p2[1])) -
          (int.parse(p1[0]) * 60 + int.parse(p1[1]));
    } catch (_) {
      return 0;
    }
  }

  bool _shouldShowTime(int index) {
    if (index == 0) return true;
    final diff = _timeDiffInMinutes(_messages[index - 1].time, _messages[index].time);
    return diff.abs() > 5;
  }


  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const CupertinoNavigationBarBackButton(),
        middle: Text(
          widget.chat.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => CallPage(name: widget.chat.name, callType: CallType.audio),
                ),
              ),
              child: const Icon(CupertinoIcons.phone, size: 22),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => CallPage(name: widget.chat.name, callType: CallType.video),
                ),
              ),
              child: const Icon(CupertinoIcons.videocam, size: 24),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CupertinoActivityIndicator())
                : GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final showTime = _shouldShowTime(index);
                        return Column(
                          children: [
                            if (showTime)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  msg.time,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ),
                            _MessageBubble(message: msg),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          _BottomBar(
            controller: _textController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Input Bar
// ---------------------------------------------------------------------------

class _BottomBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _BottomBar({required this.controller, required this.onSend});

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
        color: CupertinoColors.white,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Voice button
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(36, 36),
                onPressed: () => print('语音输入'),
                child: const Icon(
                  CupertinoIcons.mic,
                  size: 24,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(width: 4),
              // Text field
              Expanded(
                child: CupertinoTextField(
                  controller: widget.controller,
                  placeholder: '输入消息...',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => widget.onSend(),
                ),
              ),
              const SizedBox(width: 4),
              // Emoji button
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(36, 36),
                onPressed: () => print('表情'),
                child: const Icon(
                  CupertinoIcons.smiley,
                  size: 24,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(width: 2),
              // Send / Plus button
              if (hasText)
                CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                  onPressed: widget.onSend,
                  child: const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 28,
                    color: CupertinoColors.activeBlue,
                  ),
                )
              else
                CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                  onPressed: () => print('添加'),
                  child: const Icon(
                    CupertinoIcons.plus_circle,
                    size: 26,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final Color bgColor =
        isMe ? const Color(0xFF007AFF) : const Color(0xFFE9E9EB);
    final Color textColor =
        isMe ? CupertinoColors.white : CupertinoColors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left tail for incoming
          if (!isMe)
            CustomPaint(
              size: const Size(10, 12),
              painter: _TailPainter(
                color: bgColor,
                pointingRight: false,
              ),
            ),
          // Bubble body
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          ),
          // Right tail for outgoing
          if (isMe)
            CustomPaint(
              size: const Size(10, 12),
              painter: _TailPainter(
                color: bgColor,
                pointingRight: true,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubble Tail Triangle Painter
// ---------------------------------------------------------------------------

class _TailPainter extends CustomPainter {
  final Color color;
  final bool pointingRight;

  const _TailPainter({
    required this.color,
    required this.pointingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingRight) {
      // Right-pointing tail at bottom-right of bubble
      path.moveTo(0, size.height - 8);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Left-pointing tail at bottom-left of bubble
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height - 8);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
