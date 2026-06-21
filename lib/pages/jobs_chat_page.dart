import 'package:flutter/cupertino.dart';
import '../services/jobs_chat_service.dart';

class JobsChatPage extends StatefulWidget {
  final String channelKey;
  final String title;
  final String myId;
  final String peerName;

  const JobsChatPage({
    super.key,
    required this.channelKey,
    required this.title,
    required this.myId,
    required this.peerName,
  });

  @override
  State<JobsChatPage> createState() => _JobsChatPageState();
}

class _JobsChatPageState extends State<JobsChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> get _messages => JobsChatService.getMessages(widget.channelKey);

  @override
  void initState() {
    super.initState();
    JobsChatService.unreadNotifier.addListener(_onUnreadChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    JobsChatService.unreadNotifier.removeListener(_onUnreadChange);
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUnreadChange() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      fromId: widget.myId,
      fromName: widget.myId == 'personal' ? '我' : '${widget.myId} HR',
      toId: widget.peerName,
      toName: widget.peerName,
      text: text,
      time: DateTime.now(),
      channelKey: widget.channelKey,
    );
    JobsChatService.send(msg);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.chat_bubble, size: 48, color: CupertinoColors.systemGrey3),
                          SizedBox(height: 12),
                          Text('暂无消息', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                          SizedBox(height: 6),
                          Text('发送第一条消息开始沟通吧', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildBubble(_messages[i]),
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.fromId == widget.myId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(msg.fromName.substring(0, 1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? CupertinoColors.activeBlue : CupertinoColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(fontSize: 15, color: isMe ? CupertinoColors.white : CupertinoColors.black, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: isMe ? CupertinoColors.white.withValues(alpha: 0.7) : CupertinoColors.systemGrey2),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('我', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoTextField(
                controller: _msgCtrl,
                placeholder: '输入消息...',
                maxLines: 3,
                minLines: 1,
                padding: const EdgeInsets.symmetric(vertical: 10),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: CupertinoColors.activeBlue,
            onPressed: _send,
            child: const Icon(CupertinoIcons.paperplane_fill, size: 18, color: CupertinoColors.white),
          ),
        ],
      ),
    );
  }
}
