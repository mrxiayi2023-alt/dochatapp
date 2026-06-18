import 'package:flutter/cupertino.dart';
import 'mail_page.dart';

class MailComposePage extends StatefulWidget {
  const MailComposePage({super.key});

  @override
  State<MailComposePage> createState() => _MailComposePageState();
}

class _MailComposePageState extends State<MailComposePage> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _toController.text.trim().isNotEmpty &&
      _subjectController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty;

  void _send() {
    if (!_canSend) return;
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    setState(() => _sending = true);

    final newMail = MailItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'me@dochatapp.cn',
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trim(),
      time: timeStr,
      isRead: true,
      folder: 'sent',
    );
    allMails.insert(0, newMail);

    Navigator.of(context).pop(true);
  }

  void _saveDraft() {
    if (_bodyController.text.trim().isEmpty &&
        _subjectController.text.trim().isEmpty &&
        _toController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final now = DateTime.now();
    final timeStr =
        '${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final draft = MailItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'me@dochatapp.cn',
      subject: _subjectController.text.trim().isNotEmpty
          ? _subjectController.text.trim()
          : '(无主题)',
      body: _bodyController.text.trim().isNotEmpty
          ? _bodyController.text.trim()
          : '(空内容)',
      time: timeStr,
      isRead: false,
      folder: 'drafts',
    );
    allMails.insert(0, draft);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _sending ? null : () => _saveDraft(),
          child: const Text('取消', style: TextStyle(fontSize: 17)),
        ),
        middle: const Text('写邮件',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _sending ? null : _send,
          child: Text(
            '发送',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _canSend
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey3,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildRecipientRow(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 0.5,
                color: CupertinoColors.systemGrey4,
              ),
              _buildSubjectRow(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 0.5,
                color: CupertinoColors.systemGrey4,
              ),
              _buildBodyField(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientRow() {
    return Container(
      color: CupertinoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 56,
            child: Text(
              '收件人',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _toController,
              placeholder: '请输入邮箱地址',
              placeholderStyle: const TextStyle(
                color: CupertinoColors.systemGrey3,
                fontSize: 15,
              ),
              style: const TextStyle(fontSize: 15),
              keyboardType: TextInputType.emailAddress,
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow() {
    return Container(
      color: CupertinoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 56,
            child: Text(
              '主题',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _subjectController,
              placeholder: '请输入邮件主题',
              placeholderStyle: const TextStyle(
                color: CupertinoColors.systemGrey3,
                fontSize: 15,
              ),
              style: const TextStyle(fontSize: 15),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyField() {
    return Container(
      color: CupertinoColors.white,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: CupertinoTextField(
        controller: _bodyController,
        placeholder: '请输入邮件正文',
        placeholderStyle: const TextStyle(
          color: CupertinoColors.systemGrey3,
          fontSize: 15,
        ),
        style: const TextStyle(fontSize: 15, height: 1.6),
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}

