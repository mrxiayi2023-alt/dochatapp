import 'package:flutter/cupertino.dart';
import 'mail_page.dart';

class MailDetailPage extends StatefulWidget {
  final MailItem mail;
  const MailDetailPage({super.key, required this.mail});

  @override
  State<MailDetailPage> createState() => _MailDetailPageState();
}

class _MailDetailPageState extends State<MailDetailPage> {
  late MailItem _mail;

  @override
  void initState() {
    super.initState();
    _mail = widget.mail;
    // Mark as read
    if (!_mail.isRead) {
      final idx = allMails.indexWhere((m) => m.id == _mail.id);
      if (idx != -1) {
        allMails[idx] = MailItem(
          id: _mail.id, sender: _mail.sender, subject: _mail.subject,
          body: _mail.body, time: _mail.time, isRead: true, folder: _mail.folder,
        );
        _mail = allMails[idx];
      }
    }
  }

  void _deleteMail() {
    allMails.removeWhere((m) => m.id == _mail.id);
    Navigator.of(context).pop();
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('邮件操作'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showToast('回复功能即将上线');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_left, size: 18),
                SizedBox(width: 8),
                Text('回复'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showToast('转发功能即将上线');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_right, size: 18),
                SizedBox(width: 8),
                Text('转发'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteMail();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.delete, size: 18),
                SizedBox(width: 8),
                Text('删除'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('邮件详情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.5,
          onPressed: () => _showActionSheet(context),
          child: const Icon(CupertinoIcons.ellipsis_circle, size: 22, color: CupertinoColors.activeBlue),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              _buildBodyCard(),
              const SizedBox(height: 20),
              _buildBottomActions(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_mail.subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _mail.sender.characters.first.toUpperCase(),
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_mail.sender, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_mail.time, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _mail.body,
        style: const TextStyle(fontSize: 15, color: CupertinoColors.black, height: 1.7),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              onPressed: () => _showToast('回复功能即将上线'),
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text('回复', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoButton(
              onPressed: () => _showToast('转发功能即将上线'),
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.systemBlue,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text('转发', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ),
          const SizedBox(width: 10),
          CupertinoButton(
            onPressed: _deleteMail,
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            color: CupertinoColors.destructiveRed,
            pressedOpacity: 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Icon(CupertinoIcons.delete, size: 20, color: CupertinoColors.white),
          ),
        ],
      ),
    );
  }
}
