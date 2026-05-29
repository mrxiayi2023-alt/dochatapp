import 'package:flutter/cupertino.dart';
import '../models/chat_model.dart';
import 'chat_detail_page.dart';
import 'call_page.dart';

// ---------------------------------------------------------------------------
// Group Message Model
// ---------------------------------------------------------------------------

class GroupMessage {
  final String text;
  final String senderName;
  final bool isMe;
  final String time;

  const GroupMessage({
    required this.text,
    required this.senderName,
    this.isMe = false,
    required this.time,
  });
}

// ---------------------------------------------------------------------------
// Demo data
// ---------------------------------------------------------------------------

final List<GroupMessage> groupDemoMessages = [
  const GroupMessage(text: '大家早上好，今天讨论一下需求', senderName: '李四', isMe: false, time: '09:00'),
  const GroupMessage(text: '好的，我把文档发群里', senderName: '王五', isMe: false, time: '09:02'),
  const GroupMessage(text: '[文件] 需求文档v3.pdf', senderName: '李四', isMe: false, time: '09:03'),
  const GroupMessage(text: '收到了，我看看', senderName: '自己', isMe: true, time: '09:05'),
  const GroupMessage(text: '有个问题，第3页的流程图需要更新', senderName: '赵六', isMe: false, time: '09:10'),
  const GroupMessage(text: '好的，我来改', senderName: '李四', isMe: false, time: '09:12'),
];

// ---------------------------------------------------------------------------
// Soft colors palette for member avatars
// ---------------------------------------------------------------------------

final List<Color> _avatarColors = [
  const Color(0xFFFF6B6B), // red
  const Color(0xFFFF9F43), // orange
  const Color(0xFFFECA57), // yellow
  const Color(0xFF48DBFB), // cyan
  const Color(0xFF0ABDE3), // blue
  const Color(0xFFA29BFE), // purple
  const Color(0xFFFD79A8), // pink
  const Color(0xFF55EFC4), // mint
  const Color(0xFF6C5CE7), // indigo
  const Color(0xFF00B894), // teal
];

Color _nameToColor(String name) {
  final index = name.hashCode.abs() % _avatarColors.length;
  return _avatarColors[index];
}

// ---------------------------------------------------------------------------
// Group Chat Page
// ---------------------------------------------------------------------------

class GroupChatPage extends StatefulWidget {
  final ChatModel chat;

  const GroupChatPage({super.key, required this.chat});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final List<GroupMessage> _messages = List.from(groupDemoMessages);
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _messages.add(GroupMessage(
        text: text, senderName: '自己', isMe: true, time: timeStr,
      ));
      _textController.clear();
    });
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
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
          _MemberBar(members: widget.chat.members ?? []),
          Expanded(
            child: GestureDetector(
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
                      _GroupMessageBubble(message: msg),
                    ],
                  );
                },
              ),
            ),
          ),
          _GroupBottomBar(controller: _textController, onSend: _sendMessage),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Member Avatar Bar
// ---------------------------------------------------------------------------

class _MemberBar extends StatelessWidget {
  final List<String> members;

  const _MemberBar({required this.members});

  void _showProfileSheet(BuildContext context, String name) {
    if (name == '自己') return;
    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(),
        child: _MemberProfileCard(name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = members;
    const maxShow = 8;
    final showCount = allMembers.length > maxShow ? maxShow : allMembers.length;
    final overflow = allMembers.length > maxShow ? allMembers.length - maxShow : 0;

    return Container(
      height: 62,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int idx = 0; idx < showCount; idx++)
              _buildMemberItem(context, allMembers[idx]),
            if (overflow > 0)
              _buildOverflowItem(context, overflow),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, String name) {
    final isSelf = name == '自己';
    final child = SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _nameToColor(name),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (isSelf) return child;

    return GestureDetector(
      onTap: () => _showProfileSheet(context, name),
      child: child,
    );
  }

  Widget _buildOverflowItem(BuildContext context, int overflow) {
    return SizedBox(
      width: 50,
      child: GestureDetector(
        onTap: () => print('查看全部成员'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey5,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '+$overflow',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              '更多',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member Profile Card (bottom sheet)
// ---------------------------------------------------------------------------

class _MemberProfileCard extends StatelessWidget {
  final String name;

  const _MemberProfileCard({required this.name});

  void _sendMessage(BuildContext context) {
    Navigator.of(context).pop(); // close sheet
    final chat = ChatModel(
      name: name,
      initial: name.isNotEmpty ? name[0] : '?',
      lastMessage: '',
      time: '',
      avatarColor: _nameToColor(name),
    );
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _nameToColor(name);
    // Generate a pinyin-like ID from the name
    final id = '@${name.toLowerCase().replaceAll(RegExp(r'\s+'), '')}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 4),
            // ID
            Text(
              id,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.chat_bubble,
                    label: '发消息',
                    onTap: () => _sendMessage(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.phone,
                    label: '语音通话',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => CallPage(name: name, callType: CallType.audio),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.videocam,
                    label: '视频通话',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => CallPage(name: name, callType: CallType.video),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      borderRadius: BorderRadius.circular(12),
      color: CupertinoColors.systemGrey6,
      pressedOpacity: 0.5,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: CupertinoColors.activeBlue),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Group Message Bubble
// ---------------------------------------------------------------------------

class _GroupMessageBubble extends StatelessWidget {
  final GroupMessage message;

  const _GroupMessageBubble({required this.message});

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
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // --- Left side: avatar + name for others ---
          if (!isMe)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name above avatar
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.systemGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Avatar circle
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _nameToColor(message.senderName),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0]
                        : '?',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

          // Gap between avatar and bubble
          if (!isMe) const SizedBox(width: 6),

          // --- Bubble column ---
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Bubble with tail
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe)
                      CustomPaint(
                        size: const Size(10, 12),
                        painter: _GroupTailPainter(
                          color: bgColor, pointingRight: false,
                        ),
                      ),
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12,
                        ),
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
                    if (isMe)
                      CustomPaint(
                        size: const Size(10, 12),
                        painter: _GroupTailPainter(
                          color: bgColor, pointingRight: true,
                        ),
                      ),
                  ],
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
// Bubble Tail Painter
// ---------------------------------------------------------------------------

class _GroupTailPainter extends CustomPainter {
  final Color color;
  final bool pointingRight;

  const _GroupTailPainter({
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
      path.moveTo(0, size.height - 8);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
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


// ---------------------------------------------------------------------------
// Bottom Input Bar
// ---------------------------------------------------------------------------

class _GroupBottomBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _GroupBottomBar({required this.controller, required this.onSend});

  @override
  State<_GroupBottomBar> createState() => _GroupBottomBarState();
}

class _GroupBottomBarState extends State<_GroupBottomBar> {
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
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(36, 36),
                onPressed: () => print('语音输入'),
                child: const Icon(CupertinoIcons.mic, size: 24,
                    color: CupertinoColors.systemGrey),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CupertinoTextField(
                  controller: widget.controller,
                  placeholder: '输入消息...',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8,
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
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(36, 36),
                onPressed: () => print('表情'),
                child: const Icon(CupertinoIcons.smiley, size: 24,
                    color: CupertinoColors.systemGrey),
              ),
              const SizedBox(width: 2),
              if (hasText)
                CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                  onPressed: widget.onSend,
                  child: const Icon(CupertinoIcons.arrow_up_circle_fill,
                      size: 28, color: CupertinoColors.activeBlue),
                )
              else
                CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                  onPressed: () => print('添加'),
                  child: const Icon(CupertinoIcons.plus_circle, size: 26,
                      color: CupertinoColors.systemGrey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
