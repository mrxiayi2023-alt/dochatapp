// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：实名认证状态服务（静态模拟）

import 'package:flutter/cupertino.dart';
import '../pages/verify_page.dart';
import '../pages/jobs_company_verify_page.dart';

// ---------------------------------------------------------------------------
// Verification Service
// ---------------------------------------------------------------------------

/// 全局实名认证状态管理（静态模拟）
class VerificationService {
  VerificationService._();

  /// 当前实名认证状态：true=已认证，false=未认证
  static bool isVerified = false;

  /// 企业认证状态：none / pending / verified
  static String companyVerifyStatus = 'none';

  /// 是否已通过企业认证
  static bool get isCompanyVerified => companyVerifyStatus == 'verified';

  /// 引导企业认证：已认证→执行回调；未认证→弹窗引导去认证
  static void checkCompanyVerify(BuildContext context, VoidCallback onPassed) {
    if (isCompanyVerified) {
      onPassed();
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('需要企业认证'),
        content: const Text('发布职位需要企业认证，请先完成企业认证。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const JobsCompanyVerifyPage()),
              );
            },
            child: const Text('去认证'),
          ),
        ],
      ),
    );
  }

  /// 检查实名认证状态，未认证则弹出提示对话框
  /// [onPassed] - 已认证时执行的回调
  static void checkVerification(BuildContext context, VoidCallback onPassed, {String? title, String? message}) {
    if (isVerified) {
      onPassed();
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title ?? '需要实名认证'),
        content: Text(message ?? '该操作需要完成实名认证，请先进行认证。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const VerifyPage()),
              );
            },
            child: const Text('去认证'),
          ),
        ],
      ),
    );
  }
}
