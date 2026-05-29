import 'dart:async';
import 'dart:math' as math;

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
  static int _nextId = 0;

  final String id;
  final String text;
  final bool isMe;
  final String time; // "HH:mm"
  final String fromId;
  final bool isRead; // true = recipient has read (shown as ✓✓ blue)
  final bool isRecalled; // 是否已被撤回
  final bool isNew; // 对方发来的新消息（未读标记，进入页面后清除）
  final DateTime sentAt; // 发送时间（用于 24h 撤回判断）

  Message({
    String? id,
    required this.text,
    required this.isMe,
    required this.time,
    this.fromId = '',
    this.isRead = false,
    this.isRecalled = false,
    this.isNew = false,
    DateTime? sentAt,
  }) : id = id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}_${_nextId++}',
       sentAt = sentAt ?? DateTime.now();

  /// 创建一份拷贝，可覆盖部分字段
  Message copyWith({bool? isRead, bool? isRecalled, bool? isNew}) {
    return Message(
      id: id,
      text: text,
      isMe: isMe,
      time: time,
      fromId: fromId,
      isRead: isRead ?? this.isRead,
      isRecalled: isRecalled ?? this.isRecalled,
      isNew: isNew ?? this.isNew,
      sentAt: sentAt,
    );
  }

  /// 该消息是否可撤回（自己发送 + 24 小时内 + 未被撤回）
  bool get canRecall =>
      isMe && !isRecalled &&
      DateTime.now().difference(sentAt).inHours < 24;
}

// ---------------------------------------------------------------------------
// Chat Detail Page
// ---------------------------------------------------------------------------

class ChatDetailPage extends ConsumerStatefulWidget {
  final ChatModel chat;
  final String? targetUserId; // backend user ID for API calls
  /// 输入状态变化回调（通知父页面该会话的"对方正在输入"状态）
  final void Function(bool isTyping)? onTypingChanged;

  const ChatDetailPage({
    super.key,
    required this.chat,
    this.targetUserId,
    this.onTypingChanged,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loadingHistory = true;
  bool _useDemoFallback = false;

  // ---- 输入中状态 ----
  bool _isSelfTyping = false;  // 自己是否正在输入
  bool _isOtherTyping = false; // 对方是否正在输入
  Timer? _selfTypingTimer;     // 自己停止输入3秒后自动隐藏
  Timer? _otherTypingTimer;    // 对方停止输入3秒后自动隐藏

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _initChat();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _selfTypingTimer?.cancel();
    _otherTypingTimer?.cancel();
    WebSocketService.shared.offMessage(_onWsMessage);
    super.dispose();
  }

  Future<void> _initChat() async {
    // Register WebSocket listener for incoming messages
    final authState = ref.read(authProvider);
    final myId = authState.user?['id'] as String?;
    if (myId != null) {
      WebSocketService.shared.onMessage(_onWsMessage);
      await WebSocketService.shared.connect(myId);
    }

    // Load chat history from API
    await _loadHistory();

    // 进入聊天页面 → 标记该会话为已读（后端 API + 本地状态）
    await _markConversationRead();

    if (mounted) {
      setState(() => _loadingHistory = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  /// 标记当前会话所有消息为已读（后端预留 + 本地状态）
  Future<void> _markConversationRead() async {
    final otherId = widget.targetUserId;
    if (otherId == null || otherId.isEmpty) return;

    // 1) 调用后端 API（接口暂未实现时静默忽略）
    try {
      await ApiService.instance.markConversationRead(otherId);
    } catch (_) {
      // 后端未实现，忽略
    }

    // 2) 本地状态标记
    if (mounted) {
      setState(() {
        for (int i = 0; i < _messages.length; i++) {
          final msg = _messages[i];
          if (msg.isMe && !msg.isRead) {
            // 将我发送的、未读的消息标记为已读（已读回执）
            _messages[i] = msg.copyWith(isRead: true);
          }
          if (!msg.isMe && msg.isNew) {
            // 清除对方发来的新消息标记
            _messages[i] = msg.copyWith(isNew: false);
          }
        }
      });
    }
  }

  // -----------------------------------------------------------------------
  // 消息撤回
  // -----------------------------------------------------------------------

  /// 撤回指定索引的消息
  void _onRecallMessage(int index) {
    setState(() {
      _messages[index] = _messages[index].copyWith(isRecalled: true);
    });
  }

  // -----------------------------------------------------------------------
  // 消息删除
  // -----------------------------------------------------------------------

  /// 删除指定索引的消息
  /// [forBoth] = true 时为双向删除（预留后端 API 调用）
  void _onDeleteMessage(int index, {bool forBoth = false}) {
    final id = _messages[index].id;
    if (forBoth) {
      // TODO: 调用后端 API 双向删除
      // ApiService.instance.deleteMessage(id, forBoth: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == id));
      }
    });
  }

  // -----------------------------------------------------------------------
  // 输入中状态
  // -----------------------------------------------------------------------

  /// 输入框内容变化时触发：
  /// - 自己输入 → 显示"正在输入..."（3秒无输入后消失）
  void _onTextChanged() {
    final text = _textController.text;

    if (text.trim().isNotEmpty) {
      // ---- 自己正在输入 ----
      if (!_isSelfTyping) {
        setState(() => _isSelfTyping = true);
      }

      // 重置 3 秒定时器 — 停止输入 3 秒后"正在输入..."消失
      _selfTypingTimer?.cancel();
      _selfTypingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _isSelfTyping = false);
        }
      });

      // 预留：通过 WebSocket 通知对方我正在输入
      _sendTypingNotification();
    } else {
      // 输入框为空 → 立即隐藏"正在输入..."
      if (_isSelfTyping) {
        setState(() => _isSelfTyping = false);
      }
      _selfTypingTimer?.cancel();
    }
  }

  /// 收到对方的输入状态通知（由 WebSocket 回调调用）
  void _onOtherTyping(bool isTyping) {
    if (!mounted) return;
    if (isTyping) {
      if (!_isOtherTyping) {
        setState(() => _isOtherTyping = true);
        widget.onTypingChanged?.call(true); // 通知聊天列表
      }
      // 重置 3 秒定时器
      _otherTypingTimer?.cancel();
      _otherTypingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isOtherTyping = false;
            widget.onTypingChanged?.call(false);
          });
        }
      });
    } else {
      setState(() {
        _isOtherTyping = false;
        widget.onTypingChanged?.call(false);
      });
      _otherTypingTimer?.cancel();
    }
  }

  /// 模拟：对方正在输入（demo 用）
  void _simulateOtherTyping() {
    _onOtherTyping(true);
  }

  /// 预留：通过 WebSocket 发送输入状态通知
  void _sendTypingNotification() {
    // TODO: 接入后端 / WebSocket 后取消注释
    // final otherId = widget.targetUserId;
    // if (otherId != null) {
    //   _wsService.sendTypingStatus(toId: otherId, isTyping: true);
    // }
  }

  // -----------------------------------------------------------------------
  // 发起呼叫
  // -----------------------------------------------------------------------

  /// 发起音视频通话：调用 API → 跳转 CallPage
  void _startCall(String callType) {
    final otherId = widget.targetUserId;
    if (otherId == null || otherId.isEmpty) {
      // Demo 模式：直接跳转 CallPage（无信令）
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => CallPage(
            name: widget.chat.name,
            userId: otherId,
            callType: callType == 'audio' ? CallType.audio : CallType.video,
          ),
        ),
      );
      return;
    }

    // 调用后端 API 发起呼叫
    ApiService.instance.startCall(toUserId: otherId, callType: callType).then((result) {
      final callId = result['call_id'] as String?;
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => CallPage(
              name: widget.chat.name,
              userId: otherId,
              callType: callType == 'audio' ? CallType.audio : CallType.video,
              direction: CallDirection.outgoing,
              callId: callId,
            ),
          ),
        );
      }
    }).catchError((_) {
      // API 失败时直接跳转（demo 模式）
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => CallPage(
              name: widget.chat.name,
              userId: otherId,
              callType: callType == 'audio' ? CallType.audio : CallType.video,
            ),
          ),
        );
      }
    });
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
    final now = DateTime.now();
    final demoMessages = [
      Message(text: '你好，周末有空吗？', isMe: false, time: '14:30',
          sentAt: now.subtract(const Duration(hours: 26)), isNew: true),
      Message(text: '有空啊，怎么了？', isMe: true, time: '14:32', isRead: true,
          sentAt: now.subtract(const Duration(hours: 25))), // >24h → 不可撤回
      Message(text: '周末一起去杭州西湖旅游吧？', isMe: false, time: '14:33',
          sentAt: now.subtract(const Duration(hours: 2)), isNew: true),
      Message(text: '好啊！我早就想去了', isMe: true, time: '14:33', isRead: true,
          sentAt: now.subtract(const Duration(hours: 1))), // <24h → 可撤回
      Message(text: '我查了攻略，可以坐船游湖，还能去灵隐寺', isMe: false, time: '14:35',
          sentAt: now.subtract(const Duration(minutes: 45)), isNew: true),
      Message(text: '太棒了，那我订酒店', isMe: true, time: '14:36', isRead: false,
          sentAt: now.subtract(const Duration(minutes: 30))), // <24h → 可撤回
      Message(text: 'ok，到时候见👋', isMe: false, time: '14:37',
          sentAt: now.subtract(const Duration(minutes: 20))),
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

    final msg = Message(text: text, isMe: true, time: timeStr, isRead: false, sentAt: now);

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

    // Demo 模拟：发送消息 1~3 秒后，对方开始输入（持续 3 秒后自动消失）
    if (!_useDemoFallback) return;
    final delay = Duration(milliseconds: 1000 + (DateTime.now().millisecondsSinceEpoch % 2000));
    Future.delayed(delay, () {
      if (mounted) _simulateOtherTyping();
    });
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
              onPressed: () => _startCall('audio'),
              child: const Icon(CupertinoIcons.phone, size: 22),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              onPressed: () => _startCall('video'),
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
                            _MessageBubble(
                              message: msg,
                              onRecall: msg.canRecall
                                  ? () => _onRecallMessage(index)
                                  : null,
                              onDeleteLocal: () => _onDeleteMessage(index, forBoth: false),
                              onDeleteBoth: () => _onDeleteMessage(index, forBoth: true),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          // 输入中指示器
          if (_isSelfTyping) const _TypingIndicator(label: '正在输入'),
          if (_isOtherTyping) const _TypingIndicator(label: '对方正在输入'),
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
  final VoidCallback? onRecall;        // 撤回回调（null = 不可撤回）
  final VoidCallback? onDeleteLocal;   // 单向删除回调
  final VoidCallback? onDeleteBoth;    // 双向删除回调

  const _MessageBubble({
    required this.message,
    this.onRecall,
    this.onDeleteLocal,
    this.onDeleteBoth,
  });

  /// 弹出消息操作 ActionSheet
  void _showMessageActions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final actions = <Widget>[
          // 撤回（仅可撤回的消息显示）
          if (onRecall != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRecall?.call();
              },
              child: const Text('撤回'),
            ),
          // 单向删除
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDeleteLocal?.call();
            },
            child: const Text('单向删除'),
          ),
          // 双向删除
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDeleteBoth?.call();
            },
            child: const Text('双向删除'),
          ),
        ];

        return CupertinoActionSheet(
          title: const Text('选择操作'),
          actions: actions,
          cancelButton: CupertinoActionSheetAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isRecalled = message.isRecalled;

    // ---- 构建消息内容 Widget（正常气泡 / 已撤回灰色块） ----
    Widget buildContent() {
      if (isRecalled) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isMe ? '你撤回了一条消息' : '对方撤回了一条消息',
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      // ---- 正常消息气泡 ----
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
            // 新消息红点（对方发来的未读消息）
            if (!isMe && message.isNew)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.destructiveRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
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
            // 已读/未读状态（仅对发出的消息显示）
            if (isMe) _ReadStatus(isRead: message.isRead),
          ],
        ),
      );
    }

    // ---- 用 GestureDetector 包裹所有消息类型，支持长按 ----
    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: buildContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing Indicator
// ---------------------------------------------------------------------------

/// "正在输入..." 指示器（带三点呼吸动画）
class _TypingIndicator extends StatefulWidget {
  final String label;

  const _TypingIndicator({required this.label});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          _buildDot(0),
          _buildDot(1),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 每个点有 0.2s 的相位差
        final delay = index * 0.2;
        final t = (_controller.value - delay).clamp(0.0, 1.0);
        // 正弦波 0→1→0
        final opacity = (1.0 - math.cos(t * 2 * math.pi)) / 2;
        // 映射到 0.3 → 1.0 范围，不会完全消失
        final adjustedOpacity = 0.3 + opacity * 0.7;
        return Opacity(
          opacity: adjustedOpacity,
          child: const Padding(
            padding: EdgeInsets.only(left: 1),
            child: Text(
              '。',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Read Status Indicator
// ---------------------------------------------------------------------------

/// 已读/未读状态指示器
/// - 已读：两个蓝色勾 ✓✓
/// - 未读：一个灰色勾 ✓
class _ReadStatus extends StatelessWidget {
  final bool isRead;

  const _ReadStatus({required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: isRead
          ? SizedBox(
              width: 20,
              height: 14,
              child: Stack(
                children: [
                  // 第二个勾（靠右，蓝色）
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 12,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  // 第一个勾（靠左，蓝色，半透明重叠产生双勾效果）
                  Positioned(
                    right: 7,
                    top: 0,
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 12,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            )
          : Icon(
              CupertinoIcons.check_mark,
              size: 12,
              color: CupertinoColors.systemGrey,
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
