// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：单聊详情页面

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/websocket_service.dart';
import 'call_page.dart';

// ---------------------------------------------------------------------------
// Message Model (UI)
// ---------------------------------------------------------------------------

/// 聊天消息UI模型，包含文本、状态和时间信息
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
  final bool autoDelete; // 阅后即焚标记
  final Duration? deleteAfter; // 阅后即焚倒计时
  final bool isDestroyed; // 是否已销毁

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
    this.autoDelete = false,
    this.deleteAfter,
    this.isDestroyed = false,
  }) : id = id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}_${_nextId++}',
       sentAt = sentAt ?? DateTime.now();

  /// 创建一份拷贝，可覆盖部分字段
  Message copyWith({
    bool? isRead,
    bool? isRecalled,
    bool? isNew,
    bool? autoDelete,
    Duration? deleteAfter,
    bool? isDestroyed,
  }) {
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
      autoDelete: autoDelete ?? this.autoDelete,
      deleteAfter: deleteAfter ?? this.deleteAfter,
      isDestroyed: isDestroyed ?? this.isDestroyed,
    );
  }

  /// 该消息是否可撤回（自己发送 + 24 小时内 + 未被撤回）
  bool get canRecall =>
      isMe && !isRecalled && !isDestroyed &&
      DateTime.now().difference(sentAt).inHours < 24;
}

// ---------------------------------------------------------------------------
// Chat Detail Page
// ---------------------------------------------------------------------------

/// 单聊详情页面，支持消息发送、撤回和已读状态
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

/// ChatDetailPage的状态管理
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

  // ---- 收藏 / 多选 / 引用 ----
  final Set<String> _favoritedMessageIds = {};   // 已收藏消息 ID 集合
  bool _isMultiSelectMode = false;               // 是否处于多选模式
  final Set<String> _selectedMessageIds = {};    // 多选模式下已选消息 ID
  Message? _quotedMessage;                       // 当前引用的消息

  // ---- 阅后即焚 ----
  bool _burnAfterReadEnabled = false;
  Duration _burnAfterReadDuration = const Duration(minutes: 5);
  final Map<String, Timer> _autoDeleteTimers = {};

  @override
  /// 初始化状态，注册WebSocket监听
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _initChat();
  }

  @override
  /// 释放所有控制器、计时器和WebSocket监听
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _selfTypingTimer?.cancel();
    _otherTypingTimer?.cancel();
    for (final timer in _autoDeleteTimers.values) {
      timer.cancel();
    }
    _autoDeleteTimers.clear();
    WebSocketService.shared.offMessage(_onWsMessage);
    super.dispose();
  }

  /// 初始化聊天，加载历史消息并标记已读
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

    // Show messages with red dots FIRST, then mark as read
    if (mounted) {
      setState(() => _loadingHistory = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    // 进入聊天页面 → 标记该会话为已读（红点先显示再自动消失）
    // Use post-frame callback so red dots are visible briefly before clearing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markConversationRead();
    });
  }

  /// 标记当前会话所有消息为已读（后端预留 + 本地状态）
  /// 进入聊天页后红点先显示，再自动消失
  Future<void> _markConversationRead() async {
    final otherId = widget.targetUserId;

    // 1) 调用后端 API（仅在有效的 targetUserId 时调用）
    if (otherId != null && otherId.isNotEmpty) {
      try {
        await ApiService.instance.markConversationRead(otherId);
      } catch (_) {
        // 后端未实现，忽略
      }
    }

    // 确保红点至少显示 2.5 秒，用户能看到
    await Future.delayed(const Duration(milliseconds: 2500));

    // 2) 本地状态标记 — 无论 API 是否调用，都必须清除 isNew 标记
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        if (msg.isMe && !msg.isRead) {
          // 将我发送的、未读的消息标记为已读（已读回执）
          _messages[i] = msg.copyWith(isRead: true);
        }
        if (!msg.isMe && msg.isNew) {
          // 清除对方发来的新消息标记（红点消失）
          _messages[i] = msg.copyWith(isNew: false);
        }
      }
    });
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
        setState(() {
          _messages.removeWhere((m) => m.id == id);
          _favoritedMessageIds.remove(id);
          _selectedMessageIds.remove(id);
        });
      }
    });
  }

  // -----------------------------------------------------------------------
  // 复制 / 引用 / 收藏 / 多选
  // -----------------------------------------------------------------------

  /// 复制消息文字到剪贴板
  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: const Text('已复制到剪贴板'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  /// 引用消息 — 设置引用并在输入框聚焦
  void _quoteMessage(Message msg) {
    setState(() => _quotedMessage = msg);
    FocusScope.of(context).requestFocus();
    // 如果不在多选模式，退出多选
    if (_isMultiSelectMode) _exitMultiSelectMode();
  }

  /// 切换收藏状态
  void _toggleFavorite(String msgId) {
    setState(() {
      if (_favoritedMessageIds.contains(msgId)) {
        _favoritedMessageIds.remove(msgId);
      } else {
        _favoritedMessageIds.add(msgId);
      }
    });
  }

  /// 进入多选模式（预选当前消息）
  void _enterMultiSelectMode(String msgId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedMessageIds.clear();
      _selectedMessageIds.add(msgId);
    });
  }

  /// 在多选模式下切换某条消息的选中状态
  void _toggleMessageSelection(String msgId) {
    setState(() {
      if (_selectedMessageIds.contains(msgId)) {
        _selectedMessageIds.remove(msgId);
        // 如果没有选中任何消息，退出多选模式
        if (_selectedMessageIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedMessageIds.add(msgId);
      }
    });
  }

  /// 退出多选模式
  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
  }

  /// 批量删除选中的消息
  void _deleteSelectedMessages() {
    final toDelete = List<String>.from(_selectedMessageIds);
    setState(() {
      _messages.removeWhere((m) => toDelete.contains(m.id));
      for (final id in toDelete) {
        _favoritedMessageIds.remove(id);
      }
      _selectedMessageIds.clear();
      _isMultiSelectMode = false;
    });
  }

  /// 判断消息是否在24小时内
  bool _isWithin24Hours(Message msg) {
    return DateTime.now().difference(msg.sentAt).inHours < 24;
  }

  // -----------------------------------------------------------------------
  // 阅后即焚
  // -----------------------------------------------------------------------

  /// 阅后即焚时长选项
  static const List<({String label, Duration? duration})> _burnOptions = [
    (label: '关闭', duration: null),
    (label: '5分钟', duration: Duration(minutes: 5)),
    (label: '1天', duration: Duration(days: 1)),
    (label: '7天', duration: Duration(days: 7)),
    (label: '15天', duration: Duration(days: 15)),
    (label: '1个月', duration: Duration(days: 30)),
    (label: '3个月', duration: Duration(days: 90)),
    (label: '6个月', duration: Duration(days: 180)),
  ];

  /// 获取当前阅后即焚设置显示文字
  String get _burnLabel {
    if (!_burnAfterReadEnabled) return '阅后即焚：关闭';
    for (final opt in _burnOptions) {
      if (opt.duration == _burnAfterReadDuration) {
        return '阅后即焚：${opt.label}';
      }
    }
    return '阅后即焚：5分钟';
  }

  /// 为消息安排阅后即焚定时器
  void _scheduleAutoDelete(Message msg) {
    final dur = msg.deleteAfter;
    if (dur == null) return;
    _autoDeleteTimers[msg.id]?.cancel();
    _autoDeleteTimers[msg.id] = Timer(dur, () => _destroyMessage(msg.id));
  }

  /// 销毁指定消息（定时器回调）
  void _destroyMessage(String msgId) {
    if (!mounted) return;
    _autoDeleteTimers.remove(msgId);
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(isDestroyed: true);
      }
    });
  }

  /// 弹出导航栏设置菜单
  void _showSettingsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('设置'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showBurnSettingPicker();
            },
            child: Text(_burnLabel),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 弹出阅后即焚时间选择器
  void _showBurnSettingPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('阅后即焚设置'),
        actions: _burnOptions.map((opt) {
          final isSelected = opt.duration == null
              ? !_burnAfterReadEnabled
              : (_burnAfterReadEnabled && opt.duration == _burnAfterReadDuration);
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (opt.duration == null) {
                  _burnAfterReadEnabled = false;
                  _burnAfterReadDuration = const Duration(minutes: 5);
                } else {
                  _burnAfterReadEnabled = true;
                  _burnAfterReadDuration = opt.duration!;
                }
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(opt.label),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.check_mark,
                      size: 18, color: CupertinoColors.activeBlue),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 长按消息弹出的操作菜单
  void _showMessageActions(int index) {
    final msg = _messages[index];
    // 已销毁消息不弹出菜单
    if (msg.isDestroyed) return;
    final isMe = msg.isMe;
    final canRecall = isMe && !msg.isRecalled && _isWithin24Hours(msg);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择操作'),
        actions: [
          if (isMe && canRecall)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _onRecallMessage(index);
              },
              child: const Text('撤回'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _copyMessage(msg.text);
            },
            child: const Text('复制'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _quoteMessage(msg);
            },
            child: const Text('引用'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleFavorite(msg.id);
            },
            child: Text(_favoritedMessageIds.contains(msg.id) ? '取消收藏' : '收藏'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _enterMultiSelectMode(msg.id);
            },
            child: const Text('多选'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _onDeleteMessage(index, forBoth: false);
            },
            child: const Text('单向删除'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _onDeleteMessage(index, forBoth: true);
            },
            child: const Text('双向删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 显示收藏消息列表
  void _showFavoriteList() {
    final favMsgs = _messages
        .where((m) => _favoritedMessageIds.contains(m.id))
        .toList();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('收藏的消息',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text('${favMsgs.length} 条',
                style: const TextStyle(
                    color: CupertinoColors.systemGrey, fontSize: 13)),
          ],
        ),
        message: favMsgs.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('暂无收藏',
                    style: TextStyle(color: CupertinoColors.systemGrey)),
              )
            : null,
        actions: favMsgs.isEmpty
            ? <Widget>[]
            : [
                for (final m in favMsgs)
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _copyMessage(m.text);
                    },
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill,
                            size: 14, color: CupertinoColors.systemYellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(m.time,
                            style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('关闭'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
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

  /// 从API加载聊天历史
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
          sentAt: now.subtract(const Duration(minutes: 20)), isNew: true),
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

    // 阅后即焚：开启后收到的消息也应用当前设置
    final burnEnabled = _burnAfterReadEnabled;
    final burnDuration = burnEnabled ? _burnAfterReadDuration : null;

    final incomingMsg = Message(
      id: wsMsg.msgId ?? '',
      text: wsMsg.content,
      isMe: false,
      time: wsMsg.time,
      fromId: wsMsg.fromId,
      isNew: true,
      autoDelete: burnEnabled,
      deleteAfter: burnDuration,
    );

    setState(() {
      _messages.add(incomingMsg);
    });

    if (burnEnabled && burnDuration != null) {
      _scheduleAutoDelete(incomingMsg);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// 发送文本消息（支持引用回复）
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 如果正在引用消息，附带引用前缀
    final quoted = _quotedMessage;
    final finalText = quoted != null
        ? '「回复：${quoted.text.length > 30 ? '${quoted.text.substring(0, 30)}…' : quoted.text}」\n$text'
        : text;

    // 阅后即焚标记
    final burnEnabled = _burnAfterReadEnabled;
    final burnDuration = burnEnabled ? _burnAfterReadDuration : null;

    final msg = Message(
      text: finalText,
      isMe: true,
      time: timeStr,
      isRead: false,
      sentAt: now,
      autoDelete: burnEnabled,
      deleteAfter: burnDuration,
    );

    setState(() {
      _messages.add(msg);
      _textController.clear();
      _quotedMessage = null; // 清除引用
    });

    // 安排阅后即焚定时器
    if (burnEnabled && burnDuration != null) {
      _scheduleAutoDelete(msg);
    }

    _scrollToBottom();

    // Try to send via API
    final otherId = widget.targetUserId;
    if (otherId != null && !_useDemoFallback) {
      try {
        await ApiService.instance.sendMessage(toId: otherId, content: finalText);
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

  /// 滚动到消息列表底部
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
            // 收藏列表按钮
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              onPressed: _showFavoriteList,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(CupertinoIcons.star, size: 22),
                  if (_favoritedMessageIds.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemYellow,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(
                          '${_favoritedMessageIds.length}',
                          style: const TextStyle(
                            color: CupertinoColors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
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
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              onPressed: _showSettingsMenu,
              child: const Icon(CupertinoIcons.gear_solid, size: 22),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          // 阅后即焚状态提示条
          if (_burnAfterReadEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: CupertinoColors.systemYellow.withAlpha(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.flame, size: 14,
                      color: CupertinoColors.systemOrange),
                  const SizedBox(width: 6),
                  Text(
                    _burnLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loadingHistory
                ? const Center(child: CupertinoActivityIndicator())
                : GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (_isMultiSelectMode) _exitMultiSelectMode();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final showTime = _shouldShowTime(index);
                        final isSelected = _selectedMessageIds.contains(msg.id);
                        final isFav = _favoritedMessageIds.contains(msg.id);

                        return GestureDetector(
                          onTap: _isMultiSelectMode
                              ? () => _toggleMessageSelection(msg.id)
                              : null,
                          child: Column(
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
                                isSelected: isSelected,
                                isMultiSelectMode: _isMultiSelectMode,
                                isFavorited: isFav,
                                onRecall: msg.canRecall
                                    ? () => _onRecallMessage(index)
                                    : null,
                                onDelete: () => _onDeleteMessage(index),
                                onCopy: () => _copyMessage(msg.text),
                                onQuote: () => _quoteMessage(msg),
                                onFavorite: () => _toggleFavorite(msg.id),
                                onMultiSelect: () => _enterMultiSelectMode(msg.id),
                                onLongPress: () => _showMessageActions(index),
                                onReEdit: msg.isMe && msg.isRecalled
                                    ? () {
                                        _textController.text = msg.text;
                                        _textController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: _textController.text.length),
                                        );
                                        FocusScope.of(context).requestFocus();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          // 输入中指示器
          if (_isSelfTyping) const _TypingIndicator(label: '正在输入…'),
          if (_isOtherTyping) const _TypingIndicator(label: '对方正在输入…'),
          // 引用消息预览条
          if (_quotedMessage != null) _QuotePreviewBar(
            quotedMessage: _quotedMessage!,
            onCancel: () => setState(() => _quotedMessage = null),
          ),
          // 多选模式底部操作栏
          if (_isMultiSelectMode) _MultiSelectBar(
            selectedCount: _selectedMessageIds.length,
            onDelete: _deleteSelectedMessages,
            onCancel: _exitMultiSelectMode,
          ),
          _BottomBar(
            controller: _textController,
            onSend: _sendMessage,
            hasQuote: _quotedMessage != null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quote Preview Bar
// ---------------------------------------------------------------------------

/// 引用消息预览条，显示在输入框上方
class _QuotePreviewBar extends StatelessWidget {
  final Message quotedMessage;
  final VoidCallback onCancel;

  const _QuotePreviewBar({
    required this.quotedMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final preview = quotedMessage.text.length > 50
        ? '${quotedMessage.text.substring(0, 50)}…'
        : quotedMessage.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '引用 ${quotedMessage.isMe ? '自己' : '对方'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            onPressed: onCancel,
            child: const Icon(CupertinoIcons.xmark_circle_fill,
                size: 20, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-Select Bottom Bar
// ---------------------------------------------------------------------------

/// 多选模式底部操作栏
class _MultiSelectBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _MultiSelectBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 取消按钮
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.systemGrey4,
              onPressed: onCancel,
              child: const Text('取消',
                  style: TextStyle(fontSize: 14, color: CupertinoColors.black)),
            ),
            const Spacer(),
            // 已选数量
            Text(
              '已选 $selectedCount 条',
              style: const TextStyle(
                  fontSize: 14, color: CupertinoColors.systemGrey),
            ),
            const Spacer(),
            // 删除按钮
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.destructiveRed,
              onPressed: selectedCount > 0 ? onDelete : null,
              child: const Text('🗑️ 删除',
                  style: TextStyle(fontSize: 14, color: CupertinoColors.white)),
            ),
          ],
        ),
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
  final bool hasQuote;

  const _BottomBar({
    required this.controller,
    required this.onSend,
    this.hasQuote = false,
  });

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
                onPressed: () => () /* FIXED: removed print */,
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
                  placeholder: widget.hasQuote ? '回复引用…' : '输入消息...',
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
                onPressed: () => () /* FIXED: removed print */,
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
                  onPressed: () => () /* FIXED: removed print */,
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
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool isFavorited;
  final VoidCallback? onRecall;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onQuote;
  final VoidCallback? onFavorite;
  final VoidCallback? onMultiSelect;
  final VoidCallback? onLongPress;
  final VoidCallback? onReEdit;

  const _MessageBubble({
    required this.message,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.isFavorited = false,
    this.onRecall,
    this.onDelete,
    this.onCopy,
    this.onQuote,
    this.onFavorite,
    this.onMultiSelect,
    this.onLongPress,
    this.onReEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isRecalled = message.isRecalled;
    final isDestroyed = message.isDestroyed;

    // ---- 构建消息内容 Widget ----
    Widget buildContent() {
      // 已销毁消息显示灰色提示，无任何交互
      if (isDestroyed) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '[消息已销毁]',
                  style: TextStyle(
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

      if (isRecalled) {
        // 「重新编辑」仅对自己撤回的消息显示
        final showReEdit = isMe && onReEdit != null;
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
                child: showReEdit
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '你撤回了一条消息',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onReEdit,
                            child: const Text(
                              '重新编辑',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.activeBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
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
      final Color selectedBg = isMe
          ? CupertinoColors.activeBlue.withAlpha(200)
          : CupertinoColors.systemGrey4;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ---- 多选模式选择框（左侧） ----
            if (isMultiSelectMode && !isMe)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 6),
                child: _SelectionCircle(isSelected: isSelected),
              ),
            // 新消息红点（对方发来的未读消息，非多选模式）
            if (!isMe && message.isNew && !isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: CupertinoColors.destructiveRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.destructiveRed.withAlpha(100),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            // Left tail for incoming
            if (!isMe)
              CustomPaint(
                size: const Size(10, 12),
                painter: _TailPainter(
                  color: isSelected ? selectedBg : bgColor,
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
                  color: isSelected ? selectedBg : bgColor,
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
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 收藏星标
                    if (isFavorited)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.star_fill,
                            size: 12, color: CupertinoColors.systemYellow),
                      ),
                    Text(
                      message.text,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            // Right tail for outgoing
            if (isMe)
              CustomPaint(
                size: const Size(10, 12),
                painter: _TailPainter(
                  color: isSelected ? selectedBg : bgColor,
                  pointingRight: true,
                ),
              ),
            // 已读/未读状态（仅对发出的消息显示）
            if (isMe && !isMultiSelectMode) _ReadStatus(isRead: message.isRead),
            // ---- 多选模式选择框（右侧，自己发送的消息） ----
            if (isMultiSelectMode && isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: _SelectionCircle(isSelected: isSelected),
              ),
          ],
        ),
      );
    }

    // 多选模式或已销毁消息：不触发长按菜单
    if (isMultiSelectMode || isDestroyed) {
      return buildContent();
    }

    return GestureDetector(
      onLongPress: () => onLongPress?.call(),
      child: buildContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Selection Circle (multi-select mode)
// ---------------------------------------------------------------------------

class _SelectionCircle extends StatelessWidget {
  final bool isSelected;
  const _SelectionCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? CupertinoColors.activeBlue
            : CupertinoColors.white,
        border: Border.all(
          color: isSelected
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey3,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(CupertinoIcons.check_mark,
              size: 12, color: CupertinoColors.white)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Typing Indicator
// ---------------------------------------------------------------------------

/// "正在输入…" / "对方正在输入…" 指示器
class _TypingIndicator extends StatelessWidget {
  final String label;

  const _TypingIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.systemGrey,
        ),
      ),
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

/// 聊天气泡尾部三角形绘制器
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
