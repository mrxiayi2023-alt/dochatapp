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
  final Color avatarColor;
  final String initial;
  final List<String>? members; // 群聊成员昵称列表

  const ChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isGroup = false,
    required this.avatarColor,
    required this.initial,
    this.members,
  });
}
