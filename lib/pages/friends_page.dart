import 'package:flutter/cupertino.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import 'chat_detail_page.dart';
import 'chat_page.dart';
import 'friend_requests_page.dart';
import 'group_chat_page.dart';

// ---------------------------------------------------------------------------
// Soft colors
// ---------------------------------------------------------------------------

final List<Color> _avatarColors = [
  CupertinoColors.systemBlue,
  CupertinoColors.systemGreen,
  CupertinoColors.systemOrange,
  CupertinoColors.systemPurple,
  CupertinoColors.systemPink,
  CupertinoColors.systemTeal,
  CupertinoColors.systemRed,
  CupertinoColors.systemYellow,
];

Color _nameToColor(String name) {
  final index = name.hashCode.abs() % _avatarColors.length;
  return _avatarColors[index];
}

// ---------------------------------------------------------------------------
// Friends Page
// ---------------------------------------------------------------------------

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  int _selectedSegment = 0; // 0 = 好友, 1 = 群聊
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  int _pendingRequestCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([_loadFriends(), _loadPendingCount()]);
  }

  Future<void> _loadFriends() async {
    try {
      final data = await ApiService.instance.getFriendList();
      if (mounted) {
        setState(() {
          // API 数据 + 本地通过接受追加的额外好友（确保永不丢失）
          _friends = [
            ...data.cast<Map<String, dynamic>>(),
            ..._extraDemoFriends.map((e) => Map<String, dynamic>.from(e)),
          ];
          _loading = false;
        });
      }
    } catch (_) {
      _fallbackToDemo();
    }
  }

  Future<void> _loadPendingCount() async {
    try {
      final data = await ApiService.instance.getFriendRequests();
      if (mounted) {
        setState(() => _pendingRequestCount = data.length);
      }
    } catch (_) {
      // API 失败时用 demo 数据（2 条申请）让红点可见
      if (mounted) {
        setState(() => _pendingRequestCount = 2);
      }
    }
  }

  /// demo 基础好友列表（不会被重置）
  static const List<Map<String, String>> _kDemoFriends = [
    {'user_id': '1', 'nickname': '张三', 'phone': '13800000001'},
    {'user_id': '2', 'nickname': '李四', 'phone': '13800000002'},
    {'user_id': '3', 'nickname': '王五', 'phone': '13800000003'},
    {'user_id': '4', 'nickname': '赵六', 'phone': '13800000004'},
    {'user_id': '5', 'nickname': '钱七', 'phone': '13800000005'},
    {'user_id': '6', 'nickname': '孙八', 'phone': '13800000006'},
    {'user_id': '7', 'nickname': '周九', 'phone': '13800000007'},
    {'user_id': '8', 'nickname': '吴十', 'phone': '13800000008'},
  ];

  /// 额外通过申请添加的 demo 好友（不会被覆盖）
  final List<Map<String, String>> _extraDemoFriends = [];

  void _fallbackToDemo() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _friends = [
        ..._kDemoFriends.map((e) => Map<String, dynamic>.from(e)),
        ..._extraDemoFriends.map((e) => Map<String, dynamic>.from(e)),
      ];
    });
  }

  /// 在 demo 模式下添加一个新好友到列表中
  void _addDemoFriend(String nickname, String phone) {
    final newId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    _extraDemoFriends.add({'user_id': newId, 'nickname': nickname, 'phone': phone});
    _fallbackToDemo();
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('添加好友'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '输入对方手机号',
            keyboardType: TextInputType.phone,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('发送申请'),
            onPressed: () async {
              final phone = controller.text.trim();
              Navigator.of(context).pop();
              if (phone.isEmpty) return;
              await _sendFriendRequest(phone);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(String phone) async {
    try {
      await ApiService.instance.sendFriendRequest(phone);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('好友申请已发送'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('发送失败'),
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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
  }

  void _openFriendRequests() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      CupertinoPageRoute(
        builder: (_) => const FriendRequestsPage(),
      ),
    );

    // 1) 先把接受的好友加入本地额外列表（无论 API 模式还是 demo 模式）
    if (result != null) {
      final nickname = result[kResultAcceptedNickname] ?? '';
      final phone = result[kResultAcceptedPhone] ?? '';
      final userId = result[kResultAcceptedUserId] ?? '';
      if (nickname.isNotEmpty) {
        _addDemoFriend(nickname, phone);

        // 同时向聊天列表添加一条新会话（带有未读标记）
        final chat = ChatModel(
          name: nickname,
          lastMessage: '你们已成为好友，开始聊天吧',
          time: '',
          unreadCount: 1,
          initial: nickname.isNotEmpty ? nickname.characters.first : '?',
          avatarColor: _nameToColor(nickname),
          targetUserId: userId,
        );
        ChatPage.addFriendConversation(chat);
      }
    }

    // 2) 再刷新角标
    await _loadPendingCount();

    // 3) 从 API 重新加载好友列表
    //    _loadFriends 会保留 _extraDemoFriends 中的好友，
    //    所以即使 API 还没返回刚接受的好友，他也会正常显示在列表中
    await _loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('好友'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Friend requests button with badge
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _openFriendRequests,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(CupertinoIcons.bell, size: 24),
                            if (_pendingRequestCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: CupertinoColors.destructiveRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    _pendingRequestCount > 9
                                        ? '9+'
                                        : '$_pendingRequestCount',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _showAddFriendDialog,
                        child: const Icon(CupertinoIcons.add, size: 24),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),
                SliverToBoxAdapter(
                  child: _buildSegmentedControl(),
                ),
                if (_selectedSegment == 0)
                  _buildFriendSliverList()
                else
                  _buildGroupSliverList(),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 38,
        child: CupertinoSearchTextField(
          placeholder: '搜索好友',
          backgroundColor: CupertinoColors.systemGrey6,
          itemColor: CupertinoColors.systemGrey,
          itemSize: 18,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: CupertinoSegmentedControl<int>(
        padding: const EdgeInsets.all(2),
        groupValue: _selectedSegment,
        selectedColor: CupertinoColors.activeBlue,
        borderColor: CupertinoColors.systemGrey4,
        onValueChanged: (value) {
          setState(() => _selectedSegment = value);
        },
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('好友', style: TextStyle(fontSize: 14)),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('群聊', style: TextStyle(fontSize: 14)),
          ),
        },
      ),
    );
  }

  Widget _buildFriendSliverList() {
    if (_friends.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            '暂无好友，点击右上角 + 添加',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final f = _friends[index];
          final name = f['nickname'] as String? ?? '';
          final userId = f['user_id'] as String? ?? '';
          final chatModel = ChatModel(
            name: name,
            lastMessage: '',
            time: '',
            initial: name.isNotEmpty ? name.characters.first : '?',
            avatarColor: _nameToColor(name),
            targetUserId: userId,
          );
          return _FriendItem(
            key: ValueKey(userId),
            friend: chatModel,
            isLast: index == _friends.length - 1,
          );
        },
        childCount: _friends.length,
      ),
    );
  }

  Widget _buildGroupSliverList() {
    const groups = [
      ChatModel(
        name: '项目讨论群', lastMessage: '', time: '',
        isGroup: true, initial: '项',
        avatarColor: CupertinoColors.systemGreen,
        members: ['李四', '王五', '赵六', '钱七', '自己'],
      ),
      ChatModel(
        name: '设计小组', lastMessage: '', time: '',
        isGroup: true, initial: '设',
        avatarColor: CupertinoColors.systemPink,
        members: ['钱七', '孙八', '周九', '吴十', '自己'],
      ),
    ];
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final group = groups[index];
          return _GroupItem(
            key: ValueKey(group.name),
            group: group,
            isLast: index == groups.length - 1,
          );
        },
        childCount: groups.length,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Friend Item
// ---------------------------------------------------------------------------

class _FriendItem extends StatefulWidget {
  final ChatModel friend;
  final bool isLast;

  const _FriendItem({
    super.key,
    required this.friend,
    this.isLast = false,
  });

  @override
  State<_FriendItem> createState() => _FriendItemState();
}

class _FriendItemState extends State<_FriendItem> {
  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final isLast = widget.isLast;

    return Dismissible(
      key: ValueKey('friend_${friend.targetUserId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: const Text(
          '删除好友',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onDismissed: (_) => print('删除好友：${friend.name}'),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => ChatDetailPage(chat: friend, targetUserId: friend.targetUserId),
            ),
          );
        },
        child: Container(
          height: 64,
          color: CupertinoColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: friend.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        friend.initial,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name
                    Expanded(
                      child: Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // Message button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      color: CupertinoColors.activeBlue,
                      pressedOpacity: 0.7,
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => ChatDetailPage(chat: friend, targetUserId: friend.targetUserId),
                          ),
                        );
                      },
                      child: const Text(
                        '发消息',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 68),
                  color: CupertinoColors.systemGrey5,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group Item
// ---------------------------------------------------------------------------

class _GroupItem extends StatelessWidget {
  final ChatModel group;
  final bool isLast;

  const _GroupItem({
    super.key,
    required this.group,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => GroupChatPage(chat: group),
          ),
        );
      },
      child: Container(
        height: 64,
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Group avatar (double avatar overlay)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: group.avatarColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              group.initial,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey4,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (group.members != null && group.members!.isNotEmpty)
                                  ? group.members![1][0]
                                  : '?',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Group name and member count
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.members != null
                              ? '${group.members!.length}人'
                              : '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enter button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    color: CupertinoColors.activeBlue,
                    pressedOpacity: 0.7,
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => GroupChatPage(chat: group),
                        ),
                      );
                    },
                    child: const Text(
                      '进入',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 68),
                color: CupertinoColors.systemGrey5,
              ),
          ],
        ),
      ),
    );
  }
}

