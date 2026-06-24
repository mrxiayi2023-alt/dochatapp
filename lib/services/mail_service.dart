import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MailAccount {
  final String id;
  final String email;
  final String displayName;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;
  final String username;
  final String password;
  final bool useSSL;
  final String provider;
  final bool isActive;

  const MailAccount({
    required this.id,
    required this.email,
    this.displayName = '',
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
    this.username = '',
    this.password = '',
    this.useSSL = true,
    this.provider = 'other',
    this.isActive = false,
  });

  MailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    String? username,
    String? password,
    bool? useSSL,
    String? provider,
    bool? isActive,
  }) {
    return MailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      username: username ?? this.username,
      password: password ?? this.password,
      useSSL: useSSL ?? this.useSSL,
      provider: provider ?? this.provider,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'imapHost': imapHost,
        'imapPort': imapPort,
        'smtpHost': smtpHost,
        'smtpPort': smtpPort,
        'username': username,
        'password': password,
        'useSSL': useSSL,
        'provider': provider,
        'isActive': isActive,
      };

  factory MailAccount.fromJson(Map<String, dynamic> json) => MailAccount(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        imapHost: json['imapHost'] as String? ?? '',
        imapPort: json['imapPort'] as int? ?? 993,
        smtpHost: json['smtpHost'] as String? ?? '',
        smtpPort: json['smtpPort'] as int? ?? 465,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        useSSL: json['useSSL'] as bool? ?? true,
        provider: json['provider'] as String? ?? 'other',
        isActive: json['isActive'] as bool? ?? false,
      );
}

class MailMessage {
  final String id;
  final String sender;
  final String senderName;
  final String subject;
  final String body;
  final String time;
  final bool isRead;
  final bool hasAttachments;
  final String folder;
  final String accountId;

  const MailMessage({
    required this.id,
    required this.sender,
    this.senderName = '',
    required this.subject,
    required this.body,
    required this.time,
    this.isRead = false,
    this.hasAttachments = false,
    this.folder = 'inbox',
    this.accountId = '',
  });

  MailMessage copyWith({
    String? id,
    String? sender,
    String? senderName,
    String? subject,
    String? body,
    String? time,
    bool? isRead,
    bool? hasAttachments,
    String? folder,
    String? accountId,
  }) {
    return MailMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      senderName: senderName ?? this.senderName,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      folder: folder ?? this.folder,
      accountId: accountId ?? this.accountId,
    );
  }
}

class MailService {
  MailService._();

  static const String _accountsKey = 'mail_accounts';
  static List<MailAccount> _accounts = [];
  static final Map<String, List<MailMessage>> _messages = {};
  static bool _demoInitialized = false;

  static const Map<String, Map<String, dynamic>> providerPresets = {
    'qq': {
      'label': 'QQ\u90ae\u7bb1',
      'imapHost': 'imap.qq.com',
      'imapPort': 993,
      'smtpHost': 'smtp.qq.com',
      'smtpPort': 465,
      'useSSL': true,
    },
    '163': {
      'label': '163\u90ae\u7bb1',
      'imapHost': 'imap.163.com',
      'imapPort': 993,
      'smtpHost': 'smtp.163.com',
      'smtpPort': 465,
      'useSSL': true,
    },
    'gmail': {
      'label': 'Gmail',
      'imapHost': 'imap.gmail.com',
      'imapPort': 993,
      'smtpHost': 'smtp.gmail.com',
      'smtpPort': 465,
      'useSSL': true,
    },
    'outlook': {
      'label': 'Outlook',
      'imapHost': 'outlook.office365.com',
      'imapPort': 993,
      'smtpHost': 'smtp.office365.com',
      'smtpPort': 587,
      'useSSL': true,
    },
  };

  static const Map<String, String> providerLabels = {
    'qq': 'QQ\u90ae\u7bb1',
    '163': '163\u90ae\u7bb1',
    'gmail': 'Gmail',
    'outlook': 'Outlook',
    'other': '\u5176\u4ed6\u90ae\u7bb1',
  };

  static void _initDemoData() {
    if (_demoInitialized) return;
    _demoInitialized = true;

    _messages['demo_qq'] = [
      const MailMessage(
        id: 'qq_1', sender: 'xiaoming@qq.com', senderName: '\u5c0f\u660e',
        subject: '\u5468\u672b\u805a\u4f1a\u9080\u8bf7',
        body: '\u4f60\u597d\uff01\u8fd9\u5468\u672b\u6709\u7a7a\u4e00\u8d77\u805a\u4f1a\u5417\uff1f\u6211\u4eec\u8ba1\u5212\u53bb\u65b0\u5f00\u7684\u90a3\u5bb6\u9910\u5385\uff0c\u671f\u5f85\u4f60\u7684\u56de\u590d\uff01',
        time: '10:30', isRead: false, folder: 'inbox', accountId: 'demo_qq',
      ),
      const MailMessage(
        id: 'qq_2', sender: 'service@qq.com', senderName: 'QQ\u90ae\u7bb1\u56e2\u961f',
        subject: '\u65b0\u529f\u80fd\u4e0a\u7ebf\u901a\u77e5',
        body: '\u5c0a\u656c\u7684QQ\u90ae\u7bb1\u7528\u6237\uff0c\u6211\u4eec\u6700\u8fd1\u4e0a\u7ebf\u4e86\u5168\u65b0\u7684\u90ae\u4ef6\u5206\u7c7b\u529f\u80fd\uff0c\u8ba9\u60a8\u7684\u90ae\u7bb1\u7ba1\u7406\u66f4\u52a0\u9ad8\u6548\u3002',
        time: '\u6628\u5929', isRead: true, folder: 'inbox', accountId: 'demo_qq',
      ),
      const MailMessage(
        id: 'qq_3', sender: 'me@qq.com', senderName: '\u6211',
        subject: '\u5de5\u4f5c\u603b\u7ed3\u62a5\u544a',
        body: '\u9644\u4ef6\u662f\u672c\u5468\u5de5\u4f5c\u603b\u7ed3\uff0c\u8bf7\u67e5\u6536\u3002\u672c\u5468\u4e3b\u8981\u5b8c\u6210\u4e86\u9879\u76eeA\u7684\u9700\u6c42\u5206\u6790\u548c\u67b6\u6784\u8bbe\u8ba1\u3002',
        time: '\u5468\u4e00', isRead: true, folder: 'sent', accountId: 'demo_qq',
      ),
    ];

    _messages['demo_163'] = [
      const MailMessage(
        id: '163_1', sender: 'hr@163.com', senderName: '\u62db\u8058HR',
        subject: '\u9762\u8bd5\u9080\u8bf7 - \u9ad8\u7ea7\u5f00\u53d1\u5de5\u7a0b\u5e08',
        body: '\u60a8\u597d\uff0c\u6211\u4eec\u6536\u5230\u4e86\u60a8\u7684\u7b80\u5386\uff0c\u8bda\u9080\u60a8\u53c2\u52a0\u672c\u5468\u56db\u4e0b\u53482\u70b9\u7684\u9762\u8bd5\u3002\u8bf7\u56de\u590d\u786e\u8ba4\u3002',
        time: '09:15', isRead: false, folder: 'inbox', accountId: 'demo_163',
      ),
      const MailMessage(
        id: '163_2', sender: 'newsletter@163.com', senderName: '\u79d1\u6280\u65e9\u62a5',
        subject: '\u6bcf\u65e5\u79d1\u6280\u8d44\u8baf 2026.06.24',
        body: '\u4eca\u65e5\u5934\u6761\uff1aAI\u82af\u7247\u65b0\u7a81\u7834\u2026\u2026\u591a\u5bb6\u79d1\u6280\u516c\u53f8\u53d1\u5e03\u65b0\u4e00\u4ee3\u667a\u80fd\u7ec8\u7aef\u8bbe\u5907\u2026\u2026',
        time: '06:00', isRead: false, folder: 'inbox', accountId: 'demo_163',
      ),
      const MailMessage(
        id: '163_3', sender: 'me@163.com', senderName: '\u6211',
        subject: '\u9879\u76ee\u8fdb\u5ea6\u6c47\u62a5',
        body: '\u9886\u5bfc\uff0c\u672c\u5468\u9879\u76ee\u8fdb\u5ea6\u6b63\u5e38\uff0c\u5df2\u5b8c\u6210\u7b2c\u4e00\u9636\u6bb5\u5f00\u53d1\uff0c\u4e0b\u5468\u8fdb\u5165\u6d4b\u8bd5\u9636\u6bb5\u3002',
        time: '\u6628\u5929', isRead: true, folder: 'sent', accountId: 'demo_163',
      ),
    ];

    _messages['demo_gmail'] = [
      const MailMessage(
        id: 'gmail_1', sender: 'alice@gmail.com', senderName: 'Alice',
        subject: 'Hello from Singapore!',
        body: 'Hey! Just arrived in Singapore. The weather is great. Let me know if you need anything from here.',
        time: '11:20', isRead: false, folder: 'inbox', accountId: 'demo_gmail',
      ),
      const MailMessage(
        id: 'gmail_2', sender: 'noreply@google.com', senderName: 'Google',
        subject: 'Security alert: New sign-in',
        body: 'There was a new sign-in to your Google Account from a Windows device. If this was you, ignore this email.',
        time: '3\u5929\u524d', isRead: true, folder: 'inbox', accountId: 'demo_gmail',
      ),
    ];

    _messages['demo_outlook'] = [
      const MailMessage(
        id: 'outlook_1', sender: 'teams@microsoft.com', senderName: 'Microsoft Teams',
        subject: 'Missed chat from Bob',
        body: 'You have a missed chat from Bob in the "Project Alpha" channel. Open Teams to reply.',
        time: '\u6628\u5929', isRead: false, folder: 'inbox', accountId: 'demo_outlook',
      ),
      const MailMessage(
        id: 'outlook_2', sender: 'azure@microsoft.com', senderName: 'Azure DevOps',
        subject: 'Build #2024.06.23 completed',
        body: 'The build for branch main has completed successfully. 0 errors, 0 warnings.',
        time: '\u6628\u5929', isRead: true, folder: 'inbox', accountId: 'demo_outlook',
      ),
    ];
  }

  static Future<void> loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_accountsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _accounts = list.map((e) => MailAccount.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      _accounts = [];
    }
  }

  static Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_accounts.map((a) => a.toJson()).toList());
      await prefs.setString(_accountsKey, jsonStr);
    } catch (_) {}
  }

  static Future<List<MailAccount>> getAccounts() async {
    if (_accounts.isEmpty) await loadAccounts();
    return List.unmodifiable(_accounts);
  }

  static Future<void> addAccount(MailAccount account) async {
    await loadAccounts();
    _accounts.add(account);
    await _saveAccounts();
  }

  static Future<void> removeAccount(String id) async {
    await loadAccounts();
    _accounts.removeWhere((a) => a.id == id);
    await _saveAccounts();
  }

  static Future<void> setDefaultAccount(String id) async {
    await loadAccounts();
    _accounts = _accounts.map((a) => a.copyWith(isActive: a.id == id)).toList();
    await _saveAccounts();
  }

  static Future<MailAccount?> getActiveAccount() async {
    final accounts = await getAccounts();
    if (accounts.isEmpty) return null;
    try {
      return accounts.firstWhere((a) => a.isActive);
    } catch (_) {
      return accounts.first;
    }
  }

  static Future<List<MailMessage>> getInbox(String accountId, {int page = 1, int pageSize = 20}) async {
    _initDemoData();
    try {
      final api = ApiService.instance;
      final result = await api.getInbox(page: page, pageSize: pageSize);
      final items = result['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        return items.map((item) => MailMessage(
          id: item['id'] as String? ?? '',
          sender: item['sender'] as String? ?? '',
          senderName: item['sender_name'] as String? ?? '',
          subject: item['subject'] as String? ?? '',
          body: item['body'] as String? ?? '',
          time: item['created_at'] as String? ?? '',
          isRead: item['is_read'] as bool? ?? false,
          hasAttachments: item['has_attachments'] as bool? ?? false,
          folder: 'inbox',
          accountId: accountId,
        )).toList();
      }
    } catch (_) {}
    return _getDemoMessages(accountId, 'inbox');
  }

  static Future<List<MailMessage>> getSent(String accountId, {int page = 1, int pageSize = 20}) async {
    _initDemoData();
    try {
      final api = ApiService.instance;
      final result = await api.getSentMails(page: page, pageSize: pageSize);
      final items = result['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        return items.map((item) => MailMessage(
          id: item['id'] as String? ?? '',
          sender: item['sender'] as String? ?? '',
          senderName: item['sender_name'] as String? ?? '',
          subject: item['subject'] as String? ?? '',
          body: item['body'] as String? ?? '',
          time: item['created_at'] as String? ?? '',
          isRead: item['is_read'] as bool? ?? false,
          hasAttachments: item['has_attachments'] as bool? ?? false,
          folder: 'sent',
          accountId: accountId,
        )).toList();
      }
    } catch (_) {}
    return _getDemoMessages(accountId, 'sent');
  }

  static Future<bool> sendMail(String accountId, String to, String subject, String body) async {
    try {
      final api = ApiService.instance;
      await api.sendMail({'to': to, 'subject': subject, 'body': body});
      return true;
    } catch (_) {
      _initDemoData();
      final msgId = 'sent_${DateTime.now().millisecondsSinceEpoch}';
      final msg = MailMessage(
        id: msgId, sender: to, senderName: '\u6211',
        subject: subject, body: body, time: '\u521a\u521a',
        isRead: true, folder: 'sent', accountId: accountId,
      );
      if (!_messages.containsKey(accountId)) _messages[accountId] = [];
      _messages[accountId]!.insert(0, msg);
      return true;
    }
  }

  static Future<List<MailMessage>> getMessages(String folder) async {
    _initDemoData();
    final accounts = await getAccounts();
    final combined = <MailMessage>[];
    for (final account in accounts) {
      try {
        if (folder == 'inbox') {
          combined.addAll(await getInbox(account.id));
        } else if (folder == 'sent') {
          combined.addAll(await getSent(account.id));
        }
      } catch (_) {}
    }
    if (combined.isEmpty) {
      for (final key in _messages.keys) {
        combined.addAll(_messages[key]!.where((m) => m.folder == folder));
      }
    }
    return combined;
  }

  static void markAsRead(String id) {
    for (final key in _messages.keys) {
      final idx = _messages[key]!.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _messages[key]![idx] = _messages[key]![idx].copyWith(isRead: true);
        return;
      }
    }
  }

  static void deleteMessage(String id) {
    for (final key in _messages.keys) {
      _messages[key]!.removeWhere((m) => m.id == id);
    }
  }

  static List<MailMessage> _getDemoMessages(String accountId, String folder) {
    _initDemoData();
    final msgs = _messages[accountId];
    if (msgs == null) return [];
    return msgs.where((m) => m.folder == folder).toList();
  }
}
