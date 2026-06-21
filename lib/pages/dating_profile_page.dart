import 'package:flutter/cupertino.dart';
import 'dating_page.dart';
import '../services/verification_service.dart';

class DatingProfilePage extends StatefulWidget {
  final DatingUser user;
  const DatingProfilePage({super.key, required this.user});

  @override
  State<DatingProfilePage> createState() => _DatingProfilePageState();
}

class _DatingProfilePageState extends State<DatingProfilePage> {
  late List<String> _tags;
  late String _intro;
  late String _datingCriteria;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.user.tags);
    _intro = widget.user.intro;
    _datingCriteria = widget.user.datingCriteria;
  }

  DatingUser get user => widget.user;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatarSection(),
              _buildVerificationCard(),
              _buildInfoCard(),
              _buildIntroCard(),
              _buildDatingCriteriaCard(),
              const SizedBox(height: 20),
              if (user.isSelf)
                _buildEditProfileButton(context)
              else
                _buildSendMessageButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: user.color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user.initial,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 36, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${user.age}岁', style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
            const Text(' · ', style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
            Text('${user.distance}km', style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showScoreDetail(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.star_fill, size: 18, color: CupertinoColors.systemOrange),
              const SizedBox(width: 4),
              Text(
                '恋爱分数 ${user.score}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange),
              ),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.info_circle, size: 14, color: CupertinoColors.systemGrey3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('安全认证', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _buildVerifyItem(
            CupertinoIcons.person_crop_circle_badge_checkmark,
            '实名认证',
            user.isRealNameVerified,
            passedText: '已认证',
            failedText: '未认证',
          ),
          const SizedBox(height: 10),
          _buildVerifyItem(
            CupertinoIcons.camera_viewfinder,
            '人脸识别',
            user.isFaceVerified,
            passedText: '已通过',
            failedText: '未通过',
          ),
          const SizedBox(height: 10),
          _buildVerifyItem(
            CupertinoIcons.doc_text_fill,
            '单身承诺',
            user.isSingleCommitmentSigned,
            passedText: '已签署',
            failedText: '未签署',
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyItem(IconData icon, String label, bool passed, {required String passedText, required String failedText}) {
    final statusColor = passed ? CupertinoColors.systemGreen : CupertinoColors.systemOrange;
    return Row(
      children: [
        Icon(icon, size: 20, color: CupertinoColors.systemGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Icon(
          passed ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.exclamationmark_triangle_fill,
          size: 18,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          passed ? '✅$passedText' : '⚠️$failedText',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人标签', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: user.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(tag, style: TextStyle(fontSize: 14, color: user.color, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人介绍', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            _intro,
            style: const TextStyle(fontSize: 15, color: CupertinoColors.black, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDatingCriteriaCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('择偶标准', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            _datingCriteria,
            style: const TextStyle(fontSize: 15, color: CupertinoColors.black, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          onPressed: _showEditOptions,
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          color: CupertinoColors.systemGrey3,
          pressedOpacity: 0.7,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.pencil, size: 18, color: CupertinoColors.white),
              SizedBox(width: 6),
              Text('编辑资料', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendMessageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          onPressed: () {
            VerificationService.checkVerification(
              context,
              () => _sendDatingRequest(),
              message: '发送交友请求需要完成实名认证，请先进行认证。',
            );
          },
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          color: CupertinoColors.activeBlue,
          pressedOpacity: 0.7,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.chat_bubble_fill, size: 18, color: CupertinoColors.white),
              SizedBox(width: 6),
              Text('发送消息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _sendDatingRequest() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('交友请求'),
        content: Text('向${user.name}发送交友请求？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('发送'),
            onPressed: () {
              Navigator.of(ctx).pop();
              showCupertinoDialog(
                context: context,
                builder: (ctx2) => CupertinoAlertDialog(
                  title: const Text('已发送'),
                  content: Text('交友请求已发送，${user.name}同意后可开始聊天'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('好的'),
                      onPressed: () => Navigator.of(ctx2).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showScoreDetail() {
    final u = user;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('恋爱分数详情'),
        message: Text('${u.name} 的综合评分明细'),
        actions: [
          _buildScoreItem(ctx, '真实性', u.realnessScore, 40, '身份信息真实度评估'),
          _buildScoreItem(ctx, '互动度', u.interactionScore, 30, '社区互动活跃度评估'),
          _buildScoreItem(ctx, '完整度', u.completenessScore, 20, '个人资料完善度评估'),
          _buildScoreItem(ctx, '诚信度', u.integrityScore, 10, '信用与承诺履行评估'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '综合总分: ${u.score} / 100',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('关闭'),
        ),
      ),
    );
  }

  Widget _buildScoreItem(BuildContext ctx, String label, int score, int max, String desc) {
    final ratio = (score / max).clamp(0.0, 1.0);
    final barColor = ratio >= 0.8
        ? CupertinoColors.systemGreen
        : ratio >= 0.6
            ? CupertinoColors.systemOrange
            : CupertinoColors.systemRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                '$score / $max 分',
                style: TextStyle(color: barColor, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 7,
              width: double.infinity,
              color: CupertinoColors.systemGrey5,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(color: barColor),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(desc, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  void _showEditOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('编辑资料'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _editTags();
            },
            child: const Text('编辑个人标签'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _editIntro();
            },
            child: const Text('编辑个人介绍'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _editCriteria();
            },
            child: const Text('编辑择偶标准'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _editTags() {
    final controller = TextEditingController(text: _tags.join('、'));
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('编辑个人标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('多个标签用顿号分隔', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            ),
            CupertinoTextField(
              controller: controller,
              placeholder: '输入标签',
              padding: const EdgeInsets.all(12),
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
              final newTags = controller.text
                  .split('、')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              if (newTags.isNotEmpty) {
                setState(() => _tags = newTags);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _editIntro() {
    final controller = TextEditingController(text: _intro);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('编辑个人介绍'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: '介绍一下自己',
          maxLines: 3,
          padding: const EdgeInsets.all(12),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _intro = text);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _editCriteria() {
    final controller = TextEditingController(text: _datingCriteria);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('编辑择偶标准'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: '描述你的择偶标准',
          maxLines: 3,
          padding: const EdgeInsets.all(12),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _datingCriteria = text);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
