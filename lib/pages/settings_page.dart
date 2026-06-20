// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：设置页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../services/auth_provider.dart';
import 'verify_page.dart';

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

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

/// SettingsPage的状态管理
class _SettingsPageState extends ConsumerState<SettingsPage> {
  // 深色模式状态由全局 theme_provider 管理，此处不再保留本地状态

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  /// 显示关于电邮对话框
  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('关于我们'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Icon(CupertinoIcons.mail_solid, size: 48, color: CupertinoColors.activeBlue),
            SizedBox(height: 12),
            Text('电波灵动 v1.0', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Copyright 2026 江苏栩熙晨梦网络科技有限公司 版权所有', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            SizedBox(height: 4),
            Text('客服邮箱：865357222@qq.com', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
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

  /// 显示退出登录确认对话框
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

  /// 跳转至实名认证页面
  void _navigateToVerifyPage() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const VerifyPage()),
    );
  }

  /// 显示修改密码对话框
  void _showChangePasswordDialog() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: oldPwdCtrl,
              placeholder: '当前密码',
              obscureText: true,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: newPwdCtrl,
              placeholder: '新密码',
              obscureText: true,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: confirmPwdCtrl,
              placeholder: '确认新密码',
              obscureText: true,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final oldPwd = oldPwdCtrl.text.trim();
              final newPwd = newPwdCtrl.text.trim();
              final confirmPwd = confirmPwdCtrl.text.trim();
              if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                _showSimpleToast('请填写完整信息');
                return;
              }
              if (newPwd != confirmPwd) {
                _showSimpleToast('两次新密码输入不一致');
                return;
              }
              if (newPwd.length < 6) {
                _showSimpleToast('新密码长度不能少于6位');
                return;
              }
              Navigator.of(ctx).pop();
              _showSimpleToast('密码修改成功');
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 显示设备管理操作表单
  void _showDeviceManagementSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('设备管理'),
        message: const Text('管理你的登录设备'),
        actions: [
          // 当前设备
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(CupertinoIcons.desktopcomputer, size: 22, color: CupertinoColors.activeBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Windows Chrome', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('扬州市 · ', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: CupertinoColors.systemGreen, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          const Text('在线', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Text('当前设备', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
          // 分割线
          Container(
            margin: const EdgeInsets.only(left: 54),
            height: 0.5,
            color: CupertinoColors.systemGrey5,
          ),
          // 其他设备
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(CupertinoIcons.phone, size: 22, color: CupertinoColors.systemGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('iPhone 15', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('南京市 · ', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                          const Text('2小时前在线', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // 退出其他设备按钮
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(ctx).pop();
            showCupertinoDialog(
              context: context,
              builder: (dialogCtx) => CupertinoAlertDialog(
                title: const Text('退出其他设备'),
                content: const Text('确定要退出其他所有设备的登录状态吗？'),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('取消'),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showSimpleToast('已退出其他设备');
                    },
                    child: const Text('退出其他设备'),
                  ),
                ],
              ),
            );
          },
          isDestructiveAction: true,
          child: const Text('退出其他设备'),
        ),
      ),
    );
  }

  /// 显示登录记录对话框
  void _showLoginHistoryDialog() {
    final records = [
      {'ip': '192.168.1.100', 'location': '扬州市', 'device': 'Windows Chrome', 'time': '2026-06-20 15:30', 'isCurrent': true},
      {'ip': '114.221.45.32', 'location': '南京市', 'device': 'iPhone 15', 'time': '2026-06-19 09:15', 'isCurrent': false},
      {'ip': '58.213.12.88', 'location': '南京市', 'device': 'Android Samsung', 'time': '2026-06-18 22:00', 'isCurrent': false},
      {'ip': '221.226.78.45', 'location': '扬州市', 'device': 'MacBook Pro', 'time': '2026-06-17 14:20', 'isCurrent': false},
    ];

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('登录记录'),
        content: SizedBox(
          width: double.maxFinite,
          height: 220,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = records[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    r['isCurrent'] == true ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                    size: 16,
                    color: r['isCurrent'] == true ? CupertinoColors.systemGreen : CupertinoColors.systemGrey3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              r['device'] as String,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (r['isCurrent'] == true) ...[
                              const SizedBox(width: 6),
                              const Text('(当前)', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGreen)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r['location']} · IP: ${r['ip']}',
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          r['time'] as String,
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 简单提示弹窗
  void _showSimpleToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  /// 构建设置页面UI
  Widget build(BuildContext context) {
    final isDark = ref.watch(darkModeProvider);
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
              _buildRow('修改密码', onTap: _showChangePasswordDialog, textColor: textColor),
              _buildDivider(),
              _buildVerificationRow(isDark),
              _buildDivider(),
              _buildRow('隐私设置', onTap: () {}, textColor: textColor),
              _buildDivider(),
              _buildRow('设备管理', onTap: _showDeviceManagementSheet, textColor: textColor),
              _buildDivider(),
              _buildRow('登录记录', onTap: _showLoginHistoryDialog, textColor: textColor),
            ], cardColor, textColor, isDark),
          ),
          // General section
          SliverToBoxAdapter(
            child: _buildSectionLabel('通用', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildSwitchRow('深色模式', isDark, (v) => ref.read(darkModeProvider.notifier).state = v, cardColor, textColor, isDark),
              _buildDivider(),
              _buildRow('多语言', trailing: '简体中文', onTap: () {}, textColor: textColor),
              _buildDivider(),
              _buildRow('字号设置', trailing: '标准', onTap: () {}, textColor: textColor),
            ], cardColor, textColor, isDark),
          ),
          // Storage section
          SliverToBoxAdapter(
            child: _buildSectionLabel('存储', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildRow('存储管理', trailing: '128MB', onTap: () {}, textColor: textColor),
              _buildDivider(),
              _buildRow('聊天记录备份', onTap: () {}, textColor: textColor),
            ], cardColor, textColor, isDark),
          ),
          // Other section
          SliverToBoxAdapter(
            child: _buildSectionLabel('其他', textColor, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildRow('帮助与反馈', onTap: () {}, textColor: textColor),
              _buildDivider(),
              _buildRow('关于我们', onTap: _showAboutDialog, textColor: textColor),
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

  /// 构建用户资料卡片
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

  /// 构建分组标题标签
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

  /// 构建表单卡片容器
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

  /// 构建带箭头的标准行
  Widget _buildRow(String title, {String? trailing, Widget? trailingWidget, VoidCallback? onTap, Color textColor = CupertinoColors.black}) {
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
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const Spacer(),
            if (trailingWidget != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: trailingWidget,
              ),
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
  // Verification row (with status badge)
  // ---------------------------------------------------------------------------

  /// 构建实名认证行（含认证状态标识）
  Widget _buildVerificationRow(bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isVerified = user?['is_verified'] as bool? ?? false;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.5,
      onPressed: _navigateToVerifyPage,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              '实名认证',
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 6),
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
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Switch row (no chevron)
  // ---------------------------------------------------------------------------

  /// 构建带开关的行
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

  /// 构建退出登录按钮
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