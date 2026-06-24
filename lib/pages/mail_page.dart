import 'package:flutter/cupertino.dart';
import 'mail_detail_page.dart';
import 'mail_compose_page.dart';
import '../services/mail_service.dart';

class MailPage extends StatefulWidget {
  const MailPage({super.key});
  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  List<MailAccount> _accounts = [];
  int _selectedAccountIndex = 0;
  int _selectedFolder = 0;
  List<MailMessage> _messages = [];
  bool _loading = true;

  static const _folderKeys = ['inbox', 'sent'];
  static const _folderLabels = ['\u6536\u4ef6\u7bb1', '\u5df2\u53d1\u9001'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await MailService.loadAccounts();
    final accounts = await MailService.getAccounts();
    if (accounts.isNotEmpty) {
      final active = await MailService.getActiveAccount();
      final idx = active != null
          ? accounts.indexWhere((a) => a.id == active.id)
          : 0;
      _selectedAccountIndex = idx >= 0 ? idx : 0;
    }
    _accounts = accounts;
    await _loadMessages();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMessages() async {
    if (_accounts.isEmpty) {
      _messages = [];
      return;
    }
    final account = _accounts[_selectedAccountIndex];
    final folder = _folderKeys[_selectedFolder];
    List<MailMessage> msgs;
    if (folder == 'inbox') {
      msgs = await MailService.getInbox(account.id);
    } else {
      msgs = await MailService.getSent(account.id);
    }
    if (mounted) setState(() => _messages = msgs);
  }

  void _switchAccount(int index) {
    setState(() {
      _selectedAccountIndex = index;
      _messages = [];
    });
    MailService.setDefaultAccount(_accounts[index].id);
    _loadMessages();
  }

  void _switchFolder(int index) {
    setState(() {
      _selectedFolder = index;
      _messages = [];
    });
    _loadMessages();
  }

  Future<void> _onRefresh() async {
    await _loadMessages();
  }

  void _openCompose() async {
    final account = _accounts.isNotEmpty
        ? _accounts[_selectedAccountIndex]
        : null;
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => MailComposePage(account: account),
      ),
    );
    if (result == true) {
      _loadMessages();
    }
  }

  void _openDetail(MailMessage mail) async {
    MailService.markAsRead(mail.id);
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => MailDetailPage(
          mail: mail,
          accountEmail: _accounts.isNotEmpty
              ? _accounts[_selectedAccountIndex].email
              : '',
        ),
      ),
    );
    _loadMessages();
  }

  void _showAddAccountDialog(String provider) {
    final presets = MailService.providerPresets[provider];
    final label = MailService.providerLabels[provider] ?? provider;

    String email = '';
    String password = '';
    String displayName = '';

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('\u6dfb\u52a0$label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              placeholder: '\u90ae\u7bb1\u5730\u5740',
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => email = v,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              placeholder: '\u5bc6\u7801 / \u6388\u6743\u7801',
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              placeholder: '\u663e\u793a\u540d\u79f0\uff08\u53ef\u9009\uff09',
              onChanged: (v) => displayName = v,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('\u53d6\u6d88'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('\u6dfb\u52a0'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (email.isEmpty) return;
              final id = 'acc_${DateTime.now().millisecondsSinceEpoch}';
              final account = MailAccount(
                id: id,
                email: email,
                displayName: displayName.isNotEmpty ? displayName : email.split('@')[0],
                imapHost: presets?['imapHost'] as String? ?? '',
                imapPort: presets?['imapPort'] as int? ?? 993,
                smtpHost: presets?['smtpHost'] as String? ?? '',
                smtpPort: presets?['smtpPort'] as int? ?? 465,
                useSSL: presets?['useSSL'] as bool? ?? true,
                username: email,
                password: password,
                provider: provider,
                isActive: _accounts.isEmpty,
              );
              await MailService.addAccount(account);
              await _init();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_accounts.isEmpty) {
      return _buildWelcomeScreen();
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('\u7535\u6ce2\u90ae\u7bb1'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
              ),
              SliverToBoxAdapter(child: _buildAccountSelector()),
              SliverToBoxAdapter(child: _buildFolderTabs()),
              _messages.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '\u6682\u65e0\u90ae\u4ef6',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildMailRow(_messages[index]),
                        childCount: _messages.length,
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

  Widget _buildWelcomeScreen() {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Icon(CupertinoIcons.mail, size: 80, color: CupertinoColors.systemGrey),
                const SizedBox(height: 24),
                const Text('\u6dfb\u52a0\u90ae\u7bb1\u8d26\u53f7', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('\u652f\u6301QQ\u90ae\u7bb1\u3001163\u90ae\u7bb1\u3001Gmail\u7b49\u591a\u79cd\u90ae\u7bb1',
                  style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildProviderButton(icon: CupertinoIcons.mail_solid, label: 'QQ\u90ae\u7bb1', color: const Color(0xFF1AAD19), onTap: () => _showAddAccountDialog('qq')),
                const SizedBox(height: 12),
                _buildProviderButton(icon: CupertinoIcons.mail_solid, label: '163\u90ae\u7bb1', color: const Color(0xFFDE1A1A), onTap: () => _showAddAccountDialog('163')),
                const SizedBox(height: 12),
                _buildProviderButton(icon: CupertinoIcons.mail_solid, label: 'Gmail', color: const Color(0xFF4285F4), onTap: () => _showAddAccountDialog('gmail')),
                const SizedBox(height: 12),
                _buildProviderButton(icon: CupertinoIcons.mail_solid, label: '\u5176\u4ed6\u90ae\u7bb1', color: CupertinoColors.systemGrey, onTap: () => _showAddAccountDialog('other')),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        onPressed: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        color: CupertinoColors.white,
        pressedOpacity: 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: CupertinoColors.black)),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: _showAccountPicker,
        child: Row(
          children: [
            const Icon(CupertinoIcons.mail_solid, size: 20, color: CupertinoColors.activeBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_accounts[_selectedAccountIndex].email,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _accounts[_selectedAccountIndex].displayName.isNotEmpty
                  ? _accounts[_selectedAccountIndex].displayName
                  : (MailService.providerLabels[_accounts[_selectedAccountIndex].provider] ?? ''),
              style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('\u5207\u6362\u8d26\u53f7'),
        actions: [
          for (int i = 0; i < _accounts.length; i++)
            CupertinoActionSheetAction(
              isDefaultAction: i == _selectedAccountIndex,
              onPressed: () {
                Navigator.of(ctx).pop();
                if (i != _selectedAccountIndex) _switchAccount(i);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (i == _selectedAccountIndex)
                    const Icon(CupertinoIcons.check_mark_circled_solid, size: 18, color: CupertinoColors.activeBlue),
                  if (i == _selectedAccountIndex) const SizedBox(width: 8),
                  Text(_accounts[i].email, style: TextStyle(fontWeight: i == _selectedAccountIndex ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            child: const Text('\u6dfb\u52a0\u8d26\u53f7'),
            onPressed: () { Navigator.of(ctx).pop(); _showAddAccountDialog('other'); },
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

  Widget _buildFolderTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CupertinoSegmentedControl<int>(
        groupValue: _selectedFolder,
        selectedColor: CupertinoColors.activeBlue,
        borderColor: CupertinoColors.systemGrey4,
        padding: const EdgeInsets.all(2),
        onValueChanged: _switchFolder,
        children: {
          for (int i = 0; i < _folderLabels.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(_folderLabels[i], style: const TextStyle(fontSize: 13)),
            ),
        },
      ),
    );
  }

  Widget _buildMailRow(MailMessage mail) {
    return GestureDetector(
      onTap: () => _openDetail(mail),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 1),
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: mail.isRead ? CupertinoColors.systemGrey5 : CupertinoColors.activeBlue,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                (mail.senderName.isNotEmpty ? mail.senderName : mail.sender).characters.first.toUpperCase(),
                style: TextStyle(
                  color: mail.isRead ? CupertinoColors.systemGrey : CupertinoColors.white,
                  fontSize: 16, fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mail.senderName.isNotEmpty ? mail.senderName : mail.sender,
                          style: TextStyle(fontSize: 16, fontWeight: mail.isRead ? FontWeight.w400 : FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(mail.time, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mail.subject,
                    style: TextStyle(
                      fontSize: 14,
                      color: mail.isRead ? CupertinoColors.systemGrey : CupertinoColors.black,
                      fontWeight: mail.isRead ? FontWeight.w400 : FontWeight.w500,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
