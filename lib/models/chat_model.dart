import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Chat Model
// ---------------------------------------------------------------------------

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
