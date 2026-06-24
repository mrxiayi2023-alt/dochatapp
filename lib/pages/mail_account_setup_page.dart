import 'package:flutter/cupertino.dart';
import '../services/mail_service.dart';

class MailAccountSetupPage extends StatefulWidget {
  final String provider;
  const MailAccountSetupPage({super.key, required this.provider});
  @override
  State<MailAccountSetupPage> createState() => _MailAccountSetupPageState();
}

class _MailAccountSetupPageState extends State<MailAccountSetupPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  String get _providerLabel {
    switch (widget.provider) {
      case 'qq': return 'QQ邮箱';
      case '163': return '163邮箱';
      case 'gmail': return 'Gmail';
      default: return '其他邮箱';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = MailService.providerPresets[widget.provider] ?? 
                   MailService.providerPresets['other']!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消', style: TextStyle(fontSize: 17)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text('添加$_providerLabel'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: _saving
              ? const CupertinoActivityIndicator()
              : const Text('保存', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          onPressed: _save,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.mail_solid, size: 40, color: CupertinoColors.activeBlue),
                    const SizedBox(height: 8),
                    Text(_providerLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'IMAP: ${preset['imap_host']}:${preset['imap_port']}\nSMTP: ${preset['smtp_host']}:${preset['smtp_port']}',
                      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Display name
              const Text('显示名称', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameCtrl,
                placeholder: '例如：我的QQ邮箱',
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              const Text('邮箱地址', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _emailCtrl,
                placeholder: widget.provider == 'qq' ? 'example@qq.com' :
                             widget.provider == '163' ? 'example@163.com' :
                             widget.provider == 'gmail' ? 'example@gmail.com' : 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
              ),
              const SizedBox(height: 16),

              // Password / Authorization code
              Text(
                widget.provider == 'qq' ? '授权码' : '密码',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              if (widget.provider == 'qq')
                GestureDetector(
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('如何获取授权码？'),
                        content: const Text('1. 登录QQ邮箱网页版\n2. 进入"设置"→"账户"\n3. 开启IMAP/SMTP服务\n4. 生成授权码（非QQ密码）'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('知道了'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.info, size: 14, color: CupertinoColors.activeBlue),
                      SizedBox(width: 4),
                      Text('需使用授权码而非QQ密码', style: TextStyle(fontSize: 12, color: CupertinoColors.activeBlue)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _passwordCtrl,
                placeholder: widget.provider == 'qq' ? '请输入16位授权码' : '请输入密码',
                obscureText: true,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
              ),
              const SizedBox(height: 24),

              // Server settings info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('服务器设置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('接收服务器 (IMAP): ${preset['imap_host']}:${preset['imap_port']}', 
                         style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    Text('发送服务器 (SMTP): ${preset['smtp_host']}:${preset['smtp_port']}', 
                         style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    Text('加密方式: SSL/TLS', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _saving = true);

    final preset = MailService.providerPresets[widget.provider] ?? 
                   MailService.providerPresets['other']!;

    final account = MailAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : email,
      imapHost: preset['imap_host'] as String,
      imapPort: preset['imap_port'] as int,
      smtpHost: preset['smtp_host'] as String,
      smtpPort: preset['smtp_port'] as int,
      username: email,
      password: password,
      useSSL: true,
      provider: widget.provider,
      isActive: true,
    );

    await MailService.addAccount(account);
    if (mounted) Navigator.of(context).pop();
  }
}
