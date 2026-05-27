import 'package:flutter/cupertino.dart';
import '../models/chat_model.dart';
import 'chat_detail_page.dart';
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
// Demo data
// ---------------------------------------------------------------------------

final List<ChatModel> friendList = [
  ChatModel(name: '张三', lastMessage: '', time: '', initial: '张', avatarColor: _nameToColor('张三')),
  ChatModel(name: '李四', lastMessage: '', time: '', initial: '李', avatarColor: _nameToColor('李四')),
  ChatModel(name: '王五', lastMessage: '', time: '', initial: '王', avatarColor: _nameToColor('王五')),
  ChatModel(name: '赵六', lastMessage: '', time: '', initial: '赵', avatarColor: _nameToColor('赵六')),
  ChatModel(name: '钱七', lastMessage: '', time: '', initial: '钱', avatarColor: _nameToColor('钱七')),
  ChatModel(name: '孙八', lastMessage: '', time: '', initial: '孙', avatarColor: _nameToColor('孙八')),
  ChatModel(name: '周九', lastMessage: '', time: '', initial: '周', avatarColor: _nameToColor('周九')),
  ChatModel(name: '吴十', lastMessage: '', time: '', initial: '吴', avatarColor: _nameToColor('吴十')),
];

final List<ChatModel> friendGroupList = [
  ChatModel(name: '项目讨论群', lastMessage: '', time: '', isGroup: true, initial: '项', avatarColor: CupertinoColors.systemGreen, members: const ['李四', '王五', '赵六', '钱七', '自己']),
  ChatModel(name: '设计小组', lastMessage: '', time: '', isGroup: true, initial: '设', avatarColor: CupertinoColors.systemPink, members: const ['钱七', '孙八', '周九', '吴十', '自己']),
];

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
            placeholder: '请输入好友ID或手机号',
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
            child: const Text('搜索'),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) print('搜索好友：$text');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('好友'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAddFriendDialog,
              child: const Icon(CupertinoIcons.add, size: 24),
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final friend = friendList[index];
          return _FriendItem(
            key: ValueKey(friend.name),
            friend: friend,
            isLast: index == friendList.length - 1,
          );
        },
        childCount: friendList.length,
      ),
    );
  }

  Widget _buildGroupSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final group = friendGroupList[index];
          return _GroupItem(
            key: ValueKey(group.name),
            group: group,
            isLast: index == friendGroupList.length - 1,
          );
        },
        childCount: friendGroupList.length,
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
      key: ValueKey('friend_${friend.name}'),
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
          print('打开好友：${friend.name}');
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => ChatDetailPage(chat: friend),
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
                        print('发消息给：${friend.name}');
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => ChatDetailPage(chat: friend),
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
        print('进入群聊：${group.name}');
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
                      print('进入群聊：${group.name}');
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
