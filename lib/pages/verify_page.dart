// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：实名认证页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Verify status enum
// ---------------------------------------------------------------------------

enum VerifyStatus { unverified, pending, verified }

// ---------------------------------------------------------------------------
// Verify Page
// ---------------------------------------------------------------------------

/// 实名认证页面
class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key});

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  VerifyStatus _status = VerifyStatus.unverified;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  String get _statusLabel {
    switch (_status) {
      case VerifyStatus.unverified:
        return '未认证';
      case VerifyStatus.pending:
        return '审核中';
      case VerifyStatus.verified:
        return '已认证';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case VerifyStatus.unverified:
        return CupertinoColors.systemOrange;
      case VerifyStatus.pending:
        return CupertinoColors.activeBlue;
      case VerifyStatus.verified:
        return CupertinoColors.systemGreen;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case VerifyStatus.unverified:
        return CupertinoIcons.exclamationmark_circle;
      case VerifyStatus.pending:
        return CupertinoIcons.clock;
      case VerifyStatus.verified:
        return CupertinoIcons.checkmark_seal_fill;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onFaceRecognition() {
    // Placeholder for actual face recognition SDK integration
    debugPrint('[VerifyPage] Starting face recognition...');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('人脸识别'),
        content: const Text('人脸识别功能即将上线，敬请期待。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    final name = _nameController.text.trim();
    final idCard = _idCardController.text.trim();

    if (name.isEmpty) {
      _showToast('请输入姓名');
      return;
    }
    if (idCard.isEmpty) {
      _showToast('请输入身份证号');
      return;
    }
    if (idCard.length != 18) {
      _showToast('请输入正确的18位身份证号');
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认提交'),
        content: Text('姓名：$name\n身份证号：$idCard\n\n提交后将进入审核流程，请确认信息无误。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _doSubmit();
            },
            child: const Text('确认提交'),
          ),
        ],
      ),
    );
  }

  Future<void> _doSubmit() async {
    setState(() => _submitting = true);
    try {
      // Simulate network request delay
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _status = VerifyStatus.pending;
          _submitting = false;
        });
        _showToast('认证信息已提交，请等待审核');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _showToast('提交失败，请重试');
      }
    }
  }

  void _showToast(String message) {
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
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('实名认证'),
          ),
          // Status card
          SliverToBoxAdapter(
            child: _buildStatusCard(cardColor, isDark),
          ),
          // Form section
          SliverToBoxAdapter(
            child: _buildSectionLabel('认证信息', textColor),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              _buildTextField(
                controller: _nameController,
                placeholder: '请输入真实姓名',
                prefixIcon: CupertinoIcons.person,
                textColor: textColor,
              ),
              _buildDivider(),
              _buildTextField(
                controller: _idCardController,
                placeholder: '请输入18位身份证号',
                prefixIcon: CupertinoIcons.doc_text,
                textColor: textColor,
                keyboardType: TextInputType.number,
              ),
            ], cardColor, isDark),
          ),
          // Face recognition section
          SliverToBoxAdapter(
            child: _buildSectionLabel('人脸识别', textColor),
          ),
          SliverToBoxAdapter(
            child: _buildFormCard([
              CupertinoButton(
                padding: EdgeInsets.zero,
                pressedOpacity: 0.5,
                onPressed: _status == VerifyStatus.verified ? null : _onFaceRecognition,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.camera_viewfinder, size: 20, color: CupertinoColors.systemGrey),
                      const SizedBox(width: 10),
                      Text(
                        '开始人脸识别',
                        style: TextStyle(
                          fontSize: 16,
                          color: _status == VerifyStatus.verified ? CupertinoColors.systemGrey2 : textColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
                    ],
                  ),
                ),
              ),
            ], cardColor, isDark),
          ),
          // Submit button
          SliverToBoxAdapter(
            child: _buildSubmitButton(isDark),
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
  // Status card
  // ---------------------------------------------------------------------------

  Widget _buildStatusCard(Color cardColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon, size: 24, color: _statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '认证状态',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_status == VerifyStatus.pending)
              const CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section label
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(String title, Color textColor) {
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
  // Form card
  // ---------------------------------------------------------------------------

  Widget _buildFormCard(List<Widget> children, Color cardColor, bool isDark) {
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
  // Text field
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(prefixIcon, size: 20, color: CupertinoColors.systemGrey),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: 16, color: textColor),
              placeholderStyle: const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(),
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Submit button
  // ---------------------------------------------------------------------------

  Widget _buildSubmitButton(bool isDark) {
    final canSubmit = _status != VerifyStatus.verified && !_submitting;
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
          onPressed: canSubmit ? _onSubmit : null,
          child: Center(
            child: _submitting
                ? const CupertinoActivityIndicator()
                : Text(
                    _status == VerifyStatus.verified ? '已完成认证' : '提交认证',
                    style: TextStyle(
                      fontSize: 16,
                      color: canSubmit ? CupertinoColors.activeBlue : CupertinoColors.systemGrey2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
