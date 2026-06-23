import 'package:flutter/cupertino.dart';
import 'mail_detail_page.dart';
import 'mail_compose_page.dart';
import '../services/notification_service.dart';
import '../services/mail_service.dart';

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
      MailService.getFolderMails(_folderKeys[_selectedFolder]);

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
