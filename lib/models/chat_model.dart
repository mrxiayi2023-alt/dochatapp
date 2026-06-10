// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：聊天数据模型

import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Chat Model
// ---------------------------------------------------------------------------

/// 聊天会话数据模型，包含名称、最后消息、未读数等
class ChatModel {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isGroup;
  final bool isTyping; // 对方是否正在输入
  final Color avatarColor;
  final String initial;
  final List<String>? members; // 群聊成员昵称列表
  final String? targetUserId; // backend user ID for single chats

  const ChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isGroup = false,
    this.isTyping = false,
    required this.avatarColor,
    required this.initial,
    this.members,
    this.targetUserId,
  });

  /// 创建一份拷贝，可覆盖部分字段
  ChatModel copyWith({
    String? name,
    String? lastMessage,
    String? time,
    int? unreadCount,
    bool? isGroup,
    bool? isTyping,
    Color? avatarColor,
    String? initial,
    List<String>? members,
    String? targetUserId,
  }) {
    return ChatModel(
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      isTyping: isTyping ?? this.isTyping,
      avatarColor: avatarColor ?? this.avatarColor,
      initial: initial ?? this.initial,
      members: members ?? this.members,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}
