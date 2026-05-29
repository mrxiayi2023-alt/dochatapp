import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';

// ---------------------------------------------------------------------------
// Avatar color helpers
// ---------------------------------------------------------------------------

final List<Color> _avatarColors = [
  CupertinoColors.systemBlue,
  CupertinoColors.systemGreen,
  CupertinoColors.systemOrange,
  CupertinoColors.systemPurple,
  CupertinoColors.systemPink,
  CupertinoColors.systemTeal,
  CupertinoColors.systemRed,
  CupertinoColors.systemYellow,
];

Color _nameToColor(String name) {
  return _avatarColors[name.hashCode.abs() % _avatarColors.length];
}

// ---------------------------------------------------------------------------
// Settings Page
// ---------------------------------------------------------------------------

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _darkMode = false;

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('关于电邮'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Icon(CupertinoIcons.mail_solid, size: 48, color: CupertinoColors.activeBlue),
            SizedBox(height: 12),
            Text('电邮 v1.0.0', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Copyright 2026 江苏栩熙晨梦网络科技有限公司 版权所有', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = _darkMode;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryText = isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('设置'),
          ),
          // Profile card
          SliverToBoxAdapter(
            child: _buildProfileCard(cardColor, textColor, secondaryText, isDark),
          ),
          // Account section
          SliverToBoxAdapter(
            child: _buildSectionLabel('账号', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildRow('账号安全', onTap: () => print('账号安全')),
              _buildDivider(),
              _buildRow('隐私设置', onTap: () => print('隐私设置')),
              _buildDivider(),
              _buildRow('实名认证', onTap: () => print('实名认证')),
            ], cardColor, textColor, isDark),
          ),
          // General section
          SliverToBoxAdapter(
            child: _buildSectionLabel('通用', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildSwitchRow('深色模式', _darkMode, (v) => setState(() => _darkMode = v), cardColor, textColor, isDark),
              _buildDivider(),
              _buildRow('多语言', trailing: '简体中文', onTap: () => print('多语言设置')),
              _buildDivider(),
              _buildRow('字号设置', trailing: '标准', onTap: () => print('字号设置')),
            ], cardColor, textColor, isDark),
          ),
          // Storage section
          SliverToBoxAdapter(
            child: _buildSectionLabel('存储', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildRow('存储管理', trailing: '128MB', onTap: () => print('存储管理')),
              _buildDivider(),
              _buildRow('聊天记录备份', onTap: () => print('聊天记录备份')),
            ], cardColor, textColor, isDark),
          ),
          // Other section
          SliverToBoxAdapter(
            child: _buildSectionLabel('其他', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildRow('帮助与反馈', onTap: () => print('帮助与反馈')),
              _buildDivider(),
              _buildRow('关于电邮', onTap: _showAboutDialog),
            ], cardColor, textColor, isDark),
          ),
          // Logout button
          SliverToBoxAdapter(
            child: _buildLogoutButton(isDark),
          ),
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile card
  // ---------------------------------------------------------------------------

  Widget _buildProfileCard(Color cardColor, Color textColor, Color secondaryText, bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?['nickname'] as String? ?? '用户';
    final userId = '@${user?['phone'] as String? ?? 'unknown'}';
    final userEmail = user?['email'] as String? ?? '';
    final isVerified = user?['is_verified'] as bool? ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x00000000) : CupertinoColors.systemGrey4.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _nameToColor(userName),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userName[0],
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userId,
                        style: TextStyle(fontSize: 14, color: secondaryText),
                      ),
                    ],
                  ),
                ),
                // Verification badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? CupertinoColors.systemGreen.withValues(alpha: 0.15)
                        : CupertinoColors.systemOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVerified ? '✅' : '⚠️',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isVerified ? '已认证' : '未认证',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isVerified ? CupertinoColors.systemGreen : CupertinoColors.systemOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Email
            Row(
              children: [
                Icon(CupertinoIcons.mail, size: 14, color: secondaryText),
                const SizedBox(width: 6),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section label
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(String title, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form card wrapper
  // ---------------------------------------------------------------------------

  Widget _buildFormCard(List<Widget> children, Color cardColor, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 16),
      color: CupertinoColors.systemGrey5,
    );
  }

  // ---------------------------------------------------------------------------
  // Standard row with chevron
  // ---------------------------------------------------------------------------

  Widget _buildRow(String title, {String? trailing, VoidCallback? onTap}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.5,
      onPressed: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
            ),
            const Spacer(),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  trailing,
                  style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                ),
              ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Switch row (no chevron)
  // ---------------------------------------------------------------------------

  Widget _buildSwitchRow(String title, bool value, ValueChanged<bool> onChanged, Color cardColor, Color textColor, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
          const Spacer(),
          CupertinoSwitch(
            value: value,
            activeTrackColor: CupertinoColors.activeBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout button
  // ---------------------------------------------------------------------------

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          borderRadius: BorderRadius.circular(12),
          pressedOpacity: 0.5,
          onPressed: _showLogoutDialog,
          child: const Center(
            child: Text(
              '退出登录',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.destructiveRed,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}