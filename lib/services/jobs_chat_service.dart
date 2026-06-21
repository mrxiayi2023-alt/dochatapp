// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年6月21日
// 文件说明：电波直聘双向沟通消息服务（共享状态）

import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final String text;
  final DateTime time;
  final String channelKey;

  ChatMessage({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.text,
    required this.time,
    required this.channelKey,
  });
}

/// Shared chat state for jobs module two-way communication
class JobsChatService {
  JobsChatService._();

  static final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg1', fromId: '智云科技', fromName: '智云科技HR', toId: 'personal', toName: '我',
      text: '您好，看到您投递的前端开发工程师简历，想和您进一步沟通。',
      time: DateTime(2026, 6, 21, 10, 30), channelKey: 'personal_智云科技',
    ),
    ChatMessage(
      id: 'msg2', fromId: 'personal', fromName: '我', toId: '智云科技', toName: '智云科技HR',
      text: '您好！很高兴收到您的消息，我对这个职位很感兴趣。',
      time: DateTime(2026, 6, 21, 10, 32), channelKey: 'personal_智云科技',
    ),
    ChatMessage(
      id: 'msg3', fromId: '星辰软件', fromName: '星辰软件HR', toId: 'personal', toName: '我',
      text: '您的Java后端简历已收到，方便约个面试时间吗？',
      time: DateTime(2026, 6, 21, 11, 0), channelKey: 'personal_星辰软件',
    ),
    ChatMessage(
      id: 'msg4', fromId: 'personal', fromName: '我', toId: '星辰软件', toName: '星辰软件HR',
      text: '好的，我本周三和周五下午都有空。',
      time: DateTime(2026, 6, 21, 11, 5), channelKey: 'personal_星辰软件',
    ),
    ChatMessage(
      id: 'msg5', fromId: '智云科技', fromName: '智云科技HR', toId: 'personal', toName: '我',
      text: '方便的话我们约7月1日下午2点线下面试如何？',
      time: DateTime(2026, 6, 21, 10, 35), channelKey: 'personal_智云科技',
    ),
    ChatMessage(
      id: 'msg6', fromId: '李明', fromName: '李明', toId: '智云科技', toName: '智云科技HR',
      text: '您好，我对贵公司前端开发岗位很感兴趣，想了解更多。',
      time: DateTime(2026, 6, 20, 14, 0), channelKey: '智云科技_李明',
    ),
    ChatMessage(
      id: 'msg7', fromId: '智云科技', fromName: '智云科技HR', toId: '李明', toName: '李明',
      text: '您好！感谢关注，方便发一下您的简历吗？',
      time: DateTime(2026, 6, 20, 14, 5), channelKey: '智云科技_李明',
    ),
    ChatMessage(
      id: 'msg8', fromId: '王芳', fromName: '王芳', toId: '智云科技', toName: '智云科技HR',
      text: 'HR您好，我的UI设计作品集已经发到邮箱了，请查收。',
      time: DateTime(2026, 6, 19, 9, 30), channelKey: '智云科技_王芳',
    ),
  ];

  static final ValueNotifier<int> unreadNotifier = ValueNotifier<int>(0);

  static String channelKey(String a, String b) {
    final parts = [a, b]..sort();
    return '${parts[0]}_${parts[1]}';
  }

  static List<ChatMessage> getMessages(String key) {
    return _messages.where((m) => m.channelKey == key).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  static Map<String, ChatMessage> getConversations(String identity) {
    final map = <String, ChatMessage>{};
    for (final m in _messages) {
      if (m.channelKey.contains(identity)) {
        final existing = map[m.channelKey];
        if (existing == null || m.time.isAfter(existing.time)) {
          map[m.channelKey] = m;
        }
      }
    }
    return map;
  }

  static void send(ChatMessage msg) {
    _messages.add(msg);
    _updateUnread();
  }

  static void sendFromPersonal(String companyId, String companyName, String text) {
    final key = channelKey('personal', companyId);
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      fromId: 'personal', fromName: '我', toId: companyId, toName: companyName,
      text: text, time: DateTime.now(), channelKey: key,
    );
    send(msg);
  }

  static void sendFromCompany(String companyId, String applicantName, String text) {
    final key = channelKey(companyId, applicantName);
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      fromId: companyId, fromName: '$companyId HR', toId: applicantName, toName: applicantName,
      text: text, time: DateTime.now(), channelKey: key,
    );
    send(msg);
  }

  static int get totalConversationsCount {
    final personalConvs = getConversations('personal').length;
    final companyConvs = getConversations('智云科技').length;
    return personalConvs + companyConvs;
  }

  static void _updateUnread() {
    unreadNotifier.value = totalConversationsCount;
  }

  static void initBadge() {
    _updateUnread();
  }

  static void dispose() {
    unreadNotifier.dispose();
  }
}
