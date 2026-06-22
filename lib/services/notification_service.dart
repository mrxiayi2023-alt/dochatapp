import 'package:flutter/foundation.dart';

/// 全局通知服务 — 管理6个生态的未读通知计数
/// 支持子角标（如直聘分面试邀请/简历反馈），生态卡片角标=子角标之和
class NotificationService {
  NotificationService._();

  // ═══ 子角标（细粒度）═══
  // 所有角标初始为0，只有触发具体事件时才+1，查看后才消除
  static final Map<String, int> _subBadges = {
    'jobs_interview': 0,
    'jobs_feedback': 0,
    'mail': 0,
    'dating': 0,
    'escrow': 0,
    'mall': 0,
    'housing': 0,
  };

  // ═══ 生态→子角标映射 ═══
  static const Map<String, List<String>> _ecosystemSubKeys = {
    'jobs': ['jobs_interview', 'jobs_feedback'],
    'mail': ['mail'],
    'dating': ['dating'],
    'escrow': ['escrow'],
    'mall': ['mall'],
    'housing': ['housing'],
  };

  static final ValueNotifier<int> totalNotifier = ValueNotifier<int>(0);

  // ═══ 生态级别接口 ═══

  /// 获取某生态的角标数（所有子角标之和）
  static int getBadge(String ecosystem) {
    final keys = _ecosystemSubKeys[ecosystem];
    if (keys == null) return _subBadges[ecosystem] ?? 0;
    return keys.fold(0, (sum, k) => sum + (_subBadges[k] ?? 0));
  }

  /// 获取某个子角标数
  static int getSubBadge(String key) => _subBadges[key] ?? 0;

  /// 清除某个子角标（看到哪里，哪里消）
  static void clearBadge(String key) {
    _subBadges[key] = 0;
    _notify();
  }

  /// 清除整个生态所有子角标
  static void clearEcosystem(String ecosystem) {
    final keys = _ecosystemSubKeys[ecosystem] ?? [ecosystem];
    for (final k in keys) {
      _subBadges[k] = 0;
    }
    _notify();
  }

  /// 增加某生态角标（默认加到第一个子角标）
  static void addBadge(String ecosystem, [int count = 1]) {
    final keys = _ecosystemSubKeys[ecosystem];
    if (keys != null && keys.isNotEmpty) {
      _subBadges[keys.first] = (_subBadges[keys.first] ?? 0) + count;
    } else {
      _subBadges[ecosystem] = (_subBadges[ecosystem] ?? 0) + count;
    }
    _notify();
  }

  /// 设置某个子角标数值
  static void setSubBadge(String key, int count) {
    _subBadges[key] = count;
    _notify();
  }

  /// 设置某生态角标（兼容旧接口，重置所有子角标后设置第一个）
  static void setBadge(String ecosystem, int count) {
    final keys = _ecosystemSubKeys[ecosystem] ?? [ecosystem];
    for (final k in keys) {
      _subBadges[k] = 0;
    }
    _subBadges[keys.first] = count;
    _notify();
  }

  // ═══ 总计 ═══
  static int getTotal() {
    return _subBadges.values.fold(0, (a, b) => a + b);
  }

  static void _notify() {
    totalNotifier.value = getTotal();
  }

  static void init() {
    totalNotifier.value = getTotal();
  }

  static void dispose() {
    totalNotifier.dispose();
  }
}
