import 'api_service.dart';

// ---------------------------------------------------------------------------
// MailItem model
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// MailService
// ---------------------------------------------------------------------------

class MailService {
  MailService._();

  static final List<MailItem> _mails = [];
  static bool _apiLoaded = false;
  static bool _demoLoaded = false;

  /// 是否已从API加载真实数据
  static bool get isApiLoaded => _apiLoaded;

  // 演示数据（从 mail_page.dart 迁移过来）
  static final List<MailItem> _demoMails = [
    const MailItem(id: '1', sender: 'hr@example.com', subject: '面试邀请 - 前端开发工程师', body: '您好，我们收到了您的简历，诚邀您参加面试...', time: '10:30', isRead: false, folder: 'inbox'),
    const MailItem(id: '2', sender: 'newsletter@tech.com', subject: '本周科技资讯汇总', body: '本期内容包括AI最新进展、Flutter 3.x发布...', time: '昨天', isRead: true, folder: 'inbox'),
    const MailItem(id: '3', sender: 'noreply@dochatapp.cn', subject: '账号安全提醒', body: '您的账号于异地登录，如非本人操作请及时修改密码...', time: '周一', isRead: false, folder: 'inbox'),
    const MailItem(id: '4', sender: 'me@dochatapp.cn', subject: 'Re: 项目进度汇报', body: '收到，已完成第一阶段的开发工作...', time: '周日', isRead: true, folder: 'sent'),
    const MailItem(id: '5', sender: 'me@dochatapp.cn', subject: '请假申请', body: '您好，因个人原因需要请假三天...', time: '上周五', isRead: true, folder: 'sent'),
    const MailItem(id: '6', sender: 'me@dochatapp.cn', subject: '未完成的邮件', body: '这封邮件还没写完...', time: '2天前', isRead: false, folder: 'drafts'),
  ];

  /// 标记邮件为已读
  static void markAsRead(String id) {
    final idx = _demoMails.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _demoMails[idx] = MailItem(
        id: _demoMails[idx].id,
        sender: _demoMails[idx].sender,
        subject: _demoMails[idx].subject,
        body: _demoMails[idx].body,
        time: _demoMails[idx].time,
        isRead: true,
        folder: _demoMails[idx].folder,
      );
    }
    // Also update API-loaded mails
    final apiIdx = _mails.indexWhere((m) => m.id == id);
    if (apiIdx != -1) {
      _mails[apiIdx] = MailItem(
        id: _mails[apiIdx].id,
        sender: _mails[apiIdx].sender,
        subject: _mails[apiIdx].subject,
        body: _mails[apiIdx].body,
        time: _mails[apiIdx].time,
        isRead: true,
        folder: _mails[apiIdx].folder,
      );
    }
  }

  /// 添加新邮件（发送或草稿）
  static void addMail(MailItem mail) {
    _demoMails.insert(0, mail);
  }

  /// 删除邮件
  static void deleteMail(String id) {
    _demoMails.removeWhere((m) => m.id == id);
    _mails.removeWhere((m) => m.id == id);
  }

  /// 获取指定文件夹的邮件列表
  static List<MailItem> getFolderMails(String folder) {
    if (!_demoLoaded) {
      _demoLoaded = true;
      _loadFromApi();
    }
    if (_apiLoaded && _mails.isNotEmpty) {
      return _mails.where((m) => m.folder == folder).toList();
    }
    return _demoMails.where((m) => m.folder == folder).toList();
  }

  /// 后台加载API数据
  static Future<void> _loadFromApi() async {
    try {
      final api = ApiService.instance;
      // 加载收件箱
      final inbox = await api.getInbox();
      final items = inbox['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        _mails.clear();
        for (final item in items) {
          _mails.add(MailItem(
            id: item['id'] as String? ?? '',
            sender: item['sender'] as String? ?? '',
            subject: item['subject'] as String? ?? '',
            body: item['body'] as String? ?? '',
            time: item['created_at'] as String? ?? '',
            isRead: item['is_read'] as bool? ?? false,
            folder: item['folder'] as String? ?? 'inbox',
          ));
        }
        _apiLoaded = true;
      }
    } catch (_) {
      // API 不可用，保持演示数据
    }
  }
}
