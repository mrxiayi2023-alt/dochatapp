import 'package:flutter/cupertino.dart';
import '../services/mail_service.dart';
import 'mail_compose_page.dart';

class MailDetailPage extends StatefulWidget {
  final MailMessage mail;
  final String accountEmail;

  const MailDetailPage({
    super.key,
    required this.mail,
    this.accountEmail = '',
  });

  @override
  State<MailDetailPage> createState() => _MailDetailPageState();
}

class _MailDetailPageState extends State<MailDetailPage> {
  late MailMessage _mail;

  @override
  void initState() {
    super.initState();
    _mail = widget.mail;
    if (!_mail.isRead) {
      MailService.markAsRead(_mail.id);
      _mail = _mail.copyWith(isRead: true);
    }
  }

  void _deleteMail() {
    MailService.deleteMessage(_mail.id);
    Navigator.of(context).pop();
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('\u90ae\u4ef6\u64cd\u4f5c'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _reply();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_left, size: 18),
                SizedBox(width: 8),
                Text('\u56de\u590d'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _forward();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_right, size: 18),
                SizedBox(width: 8),
                Text('\u8f6c\u53d1'),
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
                Text('\u5220\u9664'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('\u53d6\u6d88'),
        ),
      ),
    );
  }

  void _reply() {
    final account = MailAccount(
      id: _mail.accountId,
      email: widget.accountEmail.isNotEmpty ? widget.accountEmail : _mail.sender,
      displayName: '',
      imapHost: '', imapPort: 993,
      smtpHost: '', smtpPort: 465,
    );
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => MailComposePage(
          account: account,
          replyTo: _mail.sender,
          replySubject: _mail.subject,
          replyBody: _mail.body,
        ),
      ),
    );
  }

  void _forward() {
    final account = MailAccount(
      id: _mail.accountId,
      email: widget.accountEmail.isNotEmpty ? widget.accountEmail : _mail.sender,
      displayName: '',
      imapHost: '', imapPort: 993,
      smtpHost: '', smtpPort: 465,
    );
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => MailComposePage(
          account: account,
          replySubject: 'Fwd: ${_mail.subject}',
          replyBody: '\n\n--- \u8f6c\u53d1\u7684\u90ae\u4ef6 ---\n\u53d1\u4ef6\u4eba: ${_mail.sender}\n\u4e3b\u9898: ${_mail.subject}\n\n${_mail.body}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('\u90ae\u4ef6\u8be6\u60c5', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (_mail.senderName.isNotEmpty ? _mail.senderName : _mail.sender).characters.first.toUpperCase(),
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mail.senderName.isNotEmpty ? _mail.senderName : _mail.sender,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(_mail.sender, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.systemGrey),
              const SizedBox(width: 4),
              Text(_mail.time, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              if (_mail.hasAttachments) ...[
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.paperclip, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                const Text('\u6709\u9644\u4ef6', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ],
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
              onPressed: _reply,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text('\u56de\u590d', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoButton(
              onPressed: _forward,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.systemBlue,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text('\u8f6c\u53d1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
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
