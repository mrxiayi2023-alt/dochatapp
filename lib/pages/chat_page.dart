import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class ChatModel {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isGroup;
  final Color avatarColor;
  final String initial;

  const ChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isGroup = false,
    required this.avatarColor,
    required this.initial,
  });
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatListProvider = Provider<List<ChatModel>>((ref) {
  return [
    ChatModel(
      name: '张三',
      lastMessage: '周末一起去杭州西湖旅游吧？',
      time: '14:30',
      unreadCount: 3,
      initial: '张',
      avatarColor: CupertinoColors.systemBlue,
    ),
    ChatModel(
      name: '项目讨论群',
      lastMessage: '李四：[文件] 需求文档v3.pdf',
      time: '09:15',
      isGroup: true,
      initial: '项',
      avatarColor: CupertinoColors.systemGreen,
    ),
    ChatModel(
      name: '王五',
      lastMessage: '[图片]',
      time: '昨天',
      unreadCount: 1,
      initial: '王',
      avatarColor: CupertinoColors.systemOrange,
    ),
    ChatModel(
      name: '赵六',
      lastMessage: '好的，明天见',
      time: '昨天',
      initial: '赵',
      avatarColor: CupertinoColors.systemPurple,
    ),
    ChatModel(
      name: '设计小组',
      lastMessage: '钱七：[视频]',
      time: '周二',
      unreadCount: 5,
      isGroup: true,
      initial: '设',
      avatarColor: CupertinoColors.systemPink,
    ),
  ];
});

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatListProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: CustomScrollView(
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  key: ValueKey(chat.name),
                  chat: chat,
                  isLast: index == chats.length - 1,
                );
              },
              childCount: chats.length,
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
                  child: _NewChatButton(),
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
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => debugPrint('新建聊天'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
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

// Chat List Item
class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final bool isLast;
  const _ChatListItem({
    super.key,
    required this.chat,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${chat.name}_dismiss'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: const Text('删除', style: TextStyle(color: CupertinoColors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      onDismissed: (_) => debugPrint('删除聊天：${chat.name}'),
      child: GestureDetector(
        onTap: () => debugPrint('打开聊天：${chat.name}'),
        child: Container(
          height: 72,
          color: CupertinoColors.white,
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
                                        child: Icon(CupertinoIcons.person_3_fill, size: 14, color: CupertinoColors.systemGrey),
                                      ),
                                    Flexible(
                                      child: Text(
                                        chat.name,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(chat.time, style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessage,
                                  style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.unreadCount > 0) ...[  
                                SizedBox(width: 6),
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(color: CupertinoColors.activeBlue, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(
                                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                                    style: TextStyle(color: CupertinoColors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                Container(height: 0.5, margin: EdgeInsets.only(left: 72), color: CupertinoColors.systemGrey5),
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
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: chat.avatarColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(chat.initial, style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w600)),
    );
  }
}
