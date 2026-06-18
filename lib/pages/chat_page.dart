// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：聊天列表页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/websocket_service.dart';
import 'chat_detail_page.dart';
import 'group_chat_page.dart';

// ---------------------------------------------------------------------------
// Avatar colour palette (consistent colours based on name hash)
// ---------------------------------------------------------------------------

const List<Color> _kAvatarColors = [
  CupertinoColors.systemBlue,
  CupertinoColors.systemGreen,
  CupertinoColors.systemOrange,
  CupertinoColors.systemPurple,
  CupertinoColors.systemPink,
  CupertinoColors.systemRed,
  CupertinoColors.systemTeal,
  CupertinoColors.systemIndigo,
];

Color _colorFromName(String name) {
  final hash = name.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
  return _kAvatarColors[hash.abs() % _kAvatarColors.length];
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// 聊天列表页面，显示所有会话和好友申请通过后的新会话
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  /// 好友申请通过后，由 friends_page 调用，把新好友作为一条新会话加入聊天列表
  static final List<ChatModel> _pendingFriendConversations = <ChatModel>[];

  /// 触发聊天列表刷新的通知器
  static final ValueNotifier<int> friendConversationNotifier = ValueNotifier<int>(0);

  /// 当前正在查看的聊天对象的用户ID（用于跳过该会话的未读角标更新）
  static String? currentOpenChatUserId;

  /// 外部（friends_page）调用此方法添加新好友会话
  static void addFriendConversation(ChatModel chat) {
    // 避免重复添加
    final exists = _pendingFriendConversations.any((c) => c.targetUserId == chat.targetUserId);
    if (!exists) {
      _pendingFriendConversations.add(chat);
      friendConversationNotifier.value++;
    }
  }

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

/// ChatPage的状态管理
class _ChatPageState extends ConsumerState<ChatPage> {
  List<ChatModel> _chats = [];
  bool _loading = true;
  bool _wsListenerRegistered = false;

  @override
  /// 初始化状态，监听好友会话通知
  void initState() {
    super.initState();
    // 监听好友申请通过的通知
    ChatPage.friendConversationNotifier.addListener(_onFriendConversationAdded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  @override
  /// 释放监听器资源
  void dispose() {
    ChatPage.friendConversationNotifier.removeListener(_onFriendConversationAdded);
    if (_wsListenerRegistered) {
      WebSocketService.shared.offMessage(_onWsIncomingMessage);
    }
    super.dispose();
  }

  /// WebSocket 收到新消息时更新对应会话的未读角标
  void _onWsIncomingMessage(WsChatMessage msg) {
    if (!mounted) return;
    final atState = ref.read(authProvider);
    final myId = atState.user?['id'] as String?;
    if (myId == null) return;
    // 忽略自己发出的消息回显
    if (msg.fromId == myId) return;

    final fromId = msg.fromId;
    // 如果用户正在查看该会话，不增加未读角标
    if (fromId == ChatPage.currentOpenChatUserId) return;

    setState(() {
      final index = _chats.indexWhere((c) => c.targetUserId == fromId);
      if (index != -1) {
        final chat = _chats[index];
        _chats[index] = chat.copyWith(
          lastMessage: msg.content,
          time: msg.time,
          unreadCount: chat.unreadCount + 1,
        );
      } else {
        // 新会话：插入到列表顶部
        _chats.insert(
          0,
          ChatModel(
            name: fromId,
            lastMessage: msg.content,
            time: msg.time,
            unreadCount: 1,
            initial: fromId.isNotEmpty ? fromId[0] : '?',
            avatarColor: _colorFromName(fromId),
            targetUserId: fromId,
          ),
        );
      }
    });
  }

  /// 好友通过通知监听：立即把新好友追加到 _chats 列表
  void _onFriendConversationAdded() {
    if (!mounted) return;
    // 立即将 pending 中的好友追加到聊天列表（无需等待异步加载）
    _appendPendingFriendConversations();
    // 同时触发一次完整的列表刷新（加载 API 数据，合并 pending 好友）
    _loadConversations();
  }

  // -----------------------------------------------------------------------
  // Data loading
  // -----------------------------------------------------------------------

  /// 把 _pendingFriendConversations 中尚未在 _chats 里的好友追加进去，并 setState
  void _appendPendingFriendConversations() {
    if (ChatPage._pendingFriendConversations.isEmpty) return;
    bool changed = false;
    for (final friendChat in ChatPage._pendingFriendConversations) {
      final exists = _chats.any((c) => c.targetUserId == friendChat.targetUserId);
      if (!exists) {
        _chats.add(friendChat);
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  /// 加载会话列表（优先API，失败用演示数据）
  Future<void> _loadConversations() async {
    // 保留 WebSocket 监听注册（用于实时消息角标更新）
    final authState = ref.read(authProvider);
    if (!_wsListenerRegistered) {
      final myId = authState.user?['id'] as String?;
      if (myId != null) {
        WebSocketService.shared.onMessage(_onWsIncomingMessage);
        await WebSocketService.shared.connect(myId);
        _wsListenerRegistered = true;
      }
    }

    // 尝试从API加载
    try {
      final data = await ApiService.instance.getConversations();
      if (!mounted) return;
      final apiChats = <ChatModel>[];
      for (final c in data) {
        final map = c as Map<String, dynamic>;
        final name = map['nickname'] as String? ?? map['name'] as String? ?? '';
        final otherId = map['user_id'] as String? ?? map['target_id'] as String? ?? '';
        apiChats.add(ChatModel(
          name: name,
          lastMessage: map['last_message'] as String? ?? '',
          time: map['time'] as String? ?? '',
          unreadCount: map['unread_count'] as int? ?? 0,
          initial: name.isNotEmpty ? name.characters.first : '?',
          avatarColor: _colorFromName(name),
          targetUserId: otherId,
        ));
      }
      // 检查好友列表，确保所有好友都在聊天列表中（自动创建缺失的会话）
      try {
        final friends = await ApiService.instance.getFriendList();
        for (final f in friends) {
          final fMap = f as Map<String, dynamic>;
          final fid = fMap['user_id'] as String? ?? '';
          final fname = fMap['nickname'] as String? ?? '';
          if (fid.isEmpty) continue;
          final exists = apiChats.any((c) => c.targetUserId == fid);
          if (!exists) {
            apiChats.insert(0, ChatModel(
              name: fname,
              lastMessage: '',
              time: '',
              unreadCount: 0,
              initial: fname.isNotEmpty ? fname.characters.first : '?',
              avatarColor: _colorFromName(fname),
              targetUserId: fid,
            ));
          }
        }
      } catch (_) {
        // 好友列表加载失败不影响主流程
      }
      // 合并 pending 好友会话（去重，置顶）
      for (final fc in ChatPage._pendingFriendConversations) {
        final exists = apiChats.any((c) => c.targetUserId == fc.targetUserId);
        if (!exists) apiChats.insert(0, fc);
      }
      // 追加演示6条会话（去重，排在真实会话下方）
      for (final demo in _demoConversations()) {
        final exists = apiChats.any((c) => c.name == demo.name && c.isGroup == demo.isGroup);
        if (!exists) apiChats.add(demo);
      }
      setState(() {
        _loading = false;
        _chats = apiChats;
      });
    } catch (_) {
      _fallbackToDemo();
    }
  }

  /// 演示会话6条（API成功时追加到列表下方，纯UI展示）
  static List<ChatModel> _demoConversations() => const [
    ChatModel(
      name: '张三', lastMessage: '周末一起去杭州西湖旅游吧？', time: '14:30',
      unreadCount: 3, initial: '张', avatarColor: CupertinoColors.systemBlue,
    ),
    ChatModel(
      name: '项目讨论群', lastMessage: '李四：[文件] 设计稿v3.pdf', time: '09:15',
      isGroup: true, initial: '项', avatarColor: CupertinoColors.systemGreen,
      members: ['李四', '王五', '赵六', '钱七', '自己'],
    ),
    ChatModel(
      name: '王五', lastMessage: '[图片]', time: '昨天',
      unreadCount: 1, initial: '王', avatarColor: CupertinoColors.systemOrange,
    ),
    ChatModel(
      name: '赵六', lastMessage: '好的，明天见', time: '昨天',
      initial: '赵', avatarColor: CupertinoColors.systemPurple,
    ),
    ChatModel(
      name: '设计小组', lastMessage: '钱七：[视频]', time: '周二',
      unreadCount: 5, isGroup: true, initial: '设', avatarColor: CupertinoColors.systemPink,
      members: ['钱七', '孙八', '周九', '吴十', '自己'],
    ),
    ChatModel(
      name: '孙八', lastMessage: '谢谢，收到了', time: '周一',
      initial: '孙', avatarColor: CupertinoColors.systemRed,
    ),
  ];

  /// 返回演示数据列表（不 setState），测试账号置顶
  List<ChatModel> _fallbackToDemoList() {
    final chats = <ChatModel>[
      // 测试账号（置顶，用于实时消息验证）
      ChatModel(
        name: '测试账号A', lastMessage: '', time: '', unreadCount: 0,
        initial: 'A', avatarColor: CupertinoColors.systemIndigo,
        targetUserId: '18955091111',
      ),
      ChatModel(
        name: '测试账号B', lastMessage: '', time: '', unreadCount: 0,
        initial: 'B', avatarColor: CupertinoColors.systemTeal,
        targetUserId: '17612025678',
      ),
      ..._demoConversations(),
    ];

    // 追加 pending 好友会话（去重）
    for (final friendChat in ChatPage._pendingFriendConversations) {
      final exists = chats.any((c) => c.targetUserId == friendChat.targetUserId);
      if (!exists) {
        chats.add(friendChat);
      }
    }

    return chats;
  }

  /// 使用硬编码 demo 数据，并追加 pending 好友会话
  void _fallbackToDemo() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _chats = _fallbackToDemoList();
    });
  }

  // -----------------------------------------------------------------------
  // New chat dialog
  // -----------------------------------------------------------------------

  /// 当用户打开某个聊天时调用：清除未读角标
  void _onChatOpened(ChatModel chat) {
    setState(() {
      final index = _chats.indexWhere((c) => c.name == chat.name);
      if (index != -1 && _chats[index].unreadCount > 0) {
        _chats[index] = _chats[index].copyWith(unreadCount: 0);
      }
    });
  }

  /// 对方输入状态变化回调（由 ChatDetailPage 调用）
  void _onTypingStatusChanged(String chatName, bool isTyping) {
    setState(() {
      final index = _chats.indexWhere((c) => c.name == chatName);
      if (index != -1) {
        _chats[index] = _chats[index].copyWith(isTyping: isTyping);
      }
    });
  }

  Future<void> _showNewChatDialog() async {
    final phoneController = TextEditingController();

    final phone = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('新建聊天'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: phoneController,
            placeholder: '输入对方手机号',
            keyboardType: TextInputType.phone,
            autofocus: true,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('搜索'),
            onPressed: () => Navigator.of(ctx).pop(phoneController.text.trim()),
          ),
        ],
      ),
    );

    if (phone == null || phone.isEmpty) return;

    try {
      final user = await ApiService.instance.searchUser(phone);
      final userId = user['id'] as String? ?? '';
      final nickname = user['nickname'] as String? ?? phone;

      if (!mounted) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ChatDetailPage(
            chat: ChatModel(
              name: nickname,
              lastMessage: '',
              time: '',
              initial: nickname.isNotEmpty ? nickname.characters.first : '?',
              avatarColor: _colorFromName(nickname),
              targetUserId: userId,
            ),
            targetUserId: userId,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('未找到用户'),
          content: Text('手机号 $phone 未注册'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  /// 构建聊天列表UI
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('聊天'),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => debugPrint('编辑'),
                    child: const Text(
                      '编辑',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SearchBar(),
                ),
                CupertinoSliverRefreshControl(
                  onRefresh: _loadConversations,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = _chats[index];
                      return _ChatListItem(
                        key: ValueKey(chat.name),
                        chat: chat,
                        isLast: index == _chats.length - 1,
                        onChatOpened: _onChatOpened,
                        onTypingChanged: _onTypingStatusChanged,
                      );
                    },
                    childCount: _chats.length,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Stack(
                    children: [
                      const SizedBox.shrink(),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: _NewChatButton(onPressed: _showNewChatDialog),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  @override
  /// 构建聊天列表UI
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 38,
        child: CupertinoSearchTextField(
          placeholder: '搜索',
          backgroundColor: CupertinoColors.systemGrey6,
          itemColor: CupertinoColors.systemGrey,
          itemSize: 18,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Chat FAB
// ---------------------------------------------------------------------------

class _NewChatButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewChatButton({required this.onPressed});

  @override
  /// 构建聊天列表UI
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeBlue.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.pencil_ellipsis_rectangle,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat List Item
// ---------------------------------------------------------------------------

class _ChatListItem extends StatefulWidget {
  final ChatModel chat;
  final bool isLast;
  final void Function(ChatModel)? onChatOpened; // 打开聊天时的回调（清除未读角标）
  final void Function(String chatName, bool isTyping)? onTypingChanged; // 输入状态回调

  const _ChatListItem({
    super.key,
    required this.chat,
    this.isLast = false,
    this.onChatOpened,
    this.onTypingChanged,
  });
  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem> {
  bool _pressed = false;

  @override
  /// 构建聊天列表UI
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final isLast = widget.isLast;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);

        // 先清除未读角标（乐观更新）
        widget.onChatOpened?.call(chat);

        // 标记当前打开的会话，避免 WebSocket 消息重复增加角标
        ChatPage.currentOpenChatUserId = chat.targetUserId;

        // 再导航进入聊天页面（传递输入状态回调）
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => chat.isGroup
                ? GroupChatPage(chat: chat)
                : ChatDetailPage(
                    chat: chat,
                    targetUserId: chat.targetUserId,
                    onTypingChanged: (isTyping) =>
                        widget.onTypingChanged?.call(chat.name, isTyping),
                  ),
          ),
        ).then((_) {
          // 从聊天页面返回后清除当前会话标记
          ChatPage.currentOpenChatUserId = null;
        });
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Dismissible(
        key: ValueKey('${chat.name}_dismiss'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: CupertinoColors.destructiveRed,
          child: const Text('删除',
              style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ),
        onDismissed: (_) => debugPrint('删除聊天：${chat.name}'),
        child: Container(
          height: 72,
          color:
              _pressed ? CupertinoColors.systemGrey6 : CupertinoColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _Avatar(chat: chat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (chat.isGroup)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          CupertinoIcons.person_3_fill,
                                          size: 14,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        chat.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                chat.time,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  chat.isTyping ? '对方正在输入...' : chat.lastMessage,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: chat.isTyping
                                        ? CupertinoColors.systemGreen
                                        : CupertinoColors.systemGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.unreadCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.activeBlue,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(11)),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            CupertinoColors.activeBlue
                                                .withAlpha(77),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    chat.unreadCount > 99
                                        ? '99+'
                                        : '${chat.unreadCount}',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 72),
                  color: CupertinoColors.systemGrey5,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Avatar
class _Avatar extends StatelessWidget {
  final ChatModel chat;
  const _Avatar({required this.chat});
  @override
  /// 构建聊天列表UI
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration:
          BoxDecoration(color: chat.avatarColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(chat.initial,
          style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600)),
    );
  }
}
