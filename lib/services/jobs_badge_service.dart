import 'package:flutter/foundation.dart';

/// Global badge state for the jobs module, reflected on the 服务 tab icon.
class JobsBadgeService {
  JobsBadgeService._();

  /// Combined badge count: interview pending + chat conversations
  static final ValueNotifier<int> badgeNotifier = ValueNotifier<int>(0);

  static const int _pendingInterviews = 2; // personal pending interviews
  static const int _chatConversations = 3; // demo chat conversations
  static const int _receivedResumes = 3; // company received applications

  static int get total => _pendingInterviews + _chatConversations + _receivedResumes;

  static void refresh() {
    badgeNotifier.value = total;
  }

  static void init() {
    badgeNotifier.value = total;
  }

  static void dispose() {
    badgeNotifier.dispose();
  }
}
