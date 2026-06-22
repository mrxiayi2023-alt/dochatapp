import 'package:flutter/cupertino.dart';
import 'mail_detail_page.dart';
import 'mail_compose_page.dart';
import '../services/notification_service.dart';

class MailItem {
  final String id;
  final String sender;
  final String subject;
  final String body;
  final String time;
  final bool isRead;
  final String folder;

  const MailItem({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
    required this.time,
    required this.isRead,
    required this.folder,
  });
}

final List<MailItem> allMails = [
  MailItem(id: '1', sender: 'hr@example.com', subject: '面试邀请 - 前端开发工程师', body: '您好，我们收到了您的简历，诚邀您参加面试...', time: '10:30', isRead: false, folder: 'inbox'),
  MailItem(id: '2', sender: 'newsletter@tech.com', subject: '本周科技资讯汇总', body: '本期内容包括AI最新进展、Flutter 3.x发布...', time: '昨天', isRead: true, folder: 'inbox'),
  MailItem(id: '3', sender: 'noreply@dochatapp.cn', subject: '账号安全提醒', body: '您的账号于异地登录，如非本人操作请及时修改密码...', time: '周一', isRead: false, folder: 'inbox'),
  MailItem(id: '4', sender: 'me@dochatapp.cn', subject: 'Re: 项目进度汇报', body: '收到，已完成第一阶段的开发工作...', time: '周日', isRead: true, folder: 'sent'),
  MailItem(id: '5', sender: 'me@dochatapp.cn', subject: '请假申请', body: '您好，因个人原因需要请假三天...', time: '上周五', isRead: true, folder: 'sent'),
  MailItem(id: '6', sender: 'me@dochatapp.cn', subject: '未完成的邮件', body: '这封邮件还没写完...', time: '2天前', isRead: false, folder: 'drafts'),
];

class MailPage extends StatefulWidget {
  const MailPage({super.key});
  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  int _selectedFolder = 0;

  static const _folders = ['收件箱', '已发送', '草稿箱', '垃圾箱'];
  static const _folderKeys = ['inbox', 'sent', 'drafts', 'trash'];

  @override
  void initState() {
    super.initState();
    // 进入收件箱 → 清除邮箱角标
    NotificationService.clearBadge('mail');
  }

  List<MailItem> get _filtered =>
      allMails.where((m) => m.folder == _folderKeys[_selectedFolder]).toList();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('电波邮箱'),
              ),
              SliverToBoxAdapter(child: _buildEmailAddress()),
              SliverToBoxAdapter(child: _buildFolderTabs()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMailRow(_filtered[index]),
                  childCount: _filtered.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: CupertinoButton(
              onPressed: _openCompose,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: EdgeInsets.zero,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(CupertinoIcons.pencil, color: CupertinoColors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailAddress() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.mail_solid, size: 20, color: CupertinoColors.activeBlue),
          const SizedBox(width: 10),
          const Text('user@dochatapp.cn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFolderTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CupertinoSegmentedControl<int>(
        groupValue: _selectedFolder,
        selectedColor: CupertinoColors.activeBlue,
        borderColor: CupertinoColors.systemGrey4,
        padding: const EdgeInsets.all(2),
        onValueChanged: (v) => setState(() => _selectedFolder = v),
        children: {
          for (int i = 0; i < _folders.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(_folders[i], style: const TextStyle(fontSize: 13)),
            ),
        },
      ),
    );
  }

  Widget _buildMailRow(MailItem mail) {
    return GestureDetector(
      onTap: () => _openDetail(mail),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 1),
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (!mail.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mail.sender,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: mail.isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mail.subject,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                      fontWeight: mail.isRead ? FontWeight.w400 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(mail.time, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  void _openDetail(MailItem mail) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => MailDetailPage(mail: mail)),
    );
    setState(() {});
  }

  void _openCompose() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MailComposePage(),
      ),
    );
  }
}
