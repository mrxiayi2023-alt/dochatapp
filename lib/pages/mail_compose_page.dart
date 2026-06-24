import 'package:flutter/cupertino.dart';
import '../services/mail_service.dart';

class MailComposePage extends StatefulWidget {
  final MailAccount? account;
  final String? replyTo;
  final String? replySubject;
  final String? replyBody;

  const MailComposePage({
    super.key,
    this.account,
    this.replyTo,
    this.replySubject,
    this.replyBody,
  });

  @override
  State<MailComposePage> createState() => _MailComposePageState();
}

class _MailComposePageState extends State<MailComposePage> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  List<MailAccount> _accounts = [];
  late MailAccount _selectedAccount;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _accounts = await MailService.getAccounts();
    _selectedAccount = widget.account ?? (_accounts.isNotEmpty ? _accounts.first : _createDummyAccount());

    if (widget.replyTo != null) {
      _toController.text = widget.replyTo!;
    }
    if (widget.replySubject != null) {
      _subjectController.text = widget.replySubject!.startsWith('Re:')
          ? widget.replySubject!
          : 'Re: ${widget.replySubject}';
    }
    if (widget.replyBody != null) {
      _bodyController.text = '\n\n--- \u539f\u59cb\u90ae\u4ef6 ---\n${widget.replyBody}';
    }
    if (mounted) setState(() {});
  }

  MailAccount _createDummyAccount() {
    return const MailAccount(
      id: 'dummy',
      email: 'me@dochatapp.cn',
      displayName: '\u6211',
      imapHost: '', imapPort: 993,
      smtpHost: '', smtpPort: 465,
    );
  }

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

  void _send() async {
    if (!_canSend) return;
    setState(() => _sending = true);

    final success = await MailService.sendMail(
      _selectedAccount.id,
      _toController.text.trim(),
      _subjectController.text.trim(),
      _bodyController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _sending = false);
        _showError('\u53d1\u9001\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5');
      }
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('\u786e\u5b9a'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _saveDraft() {
    if (_bodyController.text.trim().isEmpty &&
        _subjectController.text.trim().isEmpty &&
        _toController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop();
  }

  void _showAccountPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('\u9009\u62e9\u53d1\u4ef6\u4eba'),
        actions: [
          for (final acc in _accounts)
            CupertinoActionSheetAction(
              isDefaultAction: acc.id == _selectedAccount.id,
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedAccount = acc);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (acc.id == _selectedAccount.id)
                    const Icon(CupertinoIcons.check_mark_circled_solid, size: 18, color: CupertinoColors.activeBlue),
                  if (acc.id == _selectedAccount.id) const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(acc.email, style: const TextStyle(fontSize: 15)),
                      if (acc.displayName.isNotEmpty)
                        Text(acc.displayName, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    ],
                  ),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _sending ? null : () => _saveDraft(),
          child: const Text('\u53d6\u6d88', style: TextStyle(fontSize: 17)),
        ),
        middle: const Text('\u5199\u90ae\u4ef6', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _sending ? null : _send,
          child: Text(
            _sending ? '\u53d1\u9001\u4e2d...' : '\u53d1\u9001',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _canSend ? CupertinoColors.activeBlue : CupertinoColors.systemGrey3,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSenderRow(),
              Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 16), color: CupertinoColors.systemGrey4),
              _buildRecipientRow(),
              Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 16), color: CupertinoColors.systemGrey4),
              _buildSubjectRow(),
              Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 16), color: CupertinoColors.systemGrey4),
              _buildBodyField(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderRow() {
    return Container(
      color: CupertinoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 56,
            child: Text('\u53d1\u4ef6\u4eba', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _accounts.length > 1 ? _showAccountPicker : null,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _selectedAccount.displayName.isNotEmpty
                          ? '${_selectedAccount.displayName} <${_selectedAccount.email}>'
                          : _selectedAccount.email,
                      style: const TextStyle(fontSize: 15, color: CupertinoColors.activeBlue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_accounts.length > 1)
                    const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.activeBlue),
                ],
              ),
            ),
          ),
        ],
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
            child: Text('\u6536\u4ef6\u4eba', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _toController,
              placeholder: '\u8bf7\u8f93\u5165\u90ae\u7bb1\u5730\u5740',
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 15),
              style: const TextStyle(fontSize: 15),
              keyboardType: TextInputType.emailAddress,
              decoration: const BoxDecoration(color: CupertinoColors.white),
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
            child: Text('\u4e3b\u9898', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _subjectController,
              placeholder: '\u8bf7\u8f93\u5165\u90ae\u4ef6\u4e3b\u9898',
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 15),
              style: const TextStyle(fontSize: 15),
              decoration: const BoxDecoration(color: CupertinoColors.white),
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
        placeholder: '\u8bf7\u8f93\u5165\u90ae\u4ef6\u6b63\u6587',
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 15),
        style: const TextStyle(fontSize: 15, height: 1.6),
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: const BoxDecoration(color: CupertinoColors.white),
      ),
    );
  }
}
