import 'package:flutter/cupertino.dart';
import 'jobs_page.dart';
import 'jobs_resume_page.dart';
import '../services/verification_service.dart';

class JobsDetailPage extends StatelessWidget {
  final JobItem job;
  const JobsDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('职位详情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              _buildInfoCard(),
              _buildDescCard(),
              const SizedBox(height: 20),
              _buildApplyButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            '¥${job.salary}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: CupertinoColors.destructiveRed),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(CupertinoIcons.building_2_fill, size: 14, color: CupertinoColors.systemGrey),
              const SizedBox(width: 4),
              Text(job.company, style: const TextStyle(fontSize: 15, color: CupertinoColors.black, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
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
          const Text('职位信息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildInfoRow(CupertinoIcons.location_solid, '工作地点', job.location),
          _buildInfoRow(CupertinoIcons.clock, '经验要求', job.experience),
          _buildInfoRow(CupertinoIcons.book, '学历要求', job.education),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: CupertinoColors.systemGrey2),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildDescCard() {
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
          const Text('职位描述', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            job.description,
            style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 投递简历 button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () => _applyJob(context),
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.paperplane_fill, size: 18, color: CupertinoColors.white),
                  SizedBox(width: 6),
                  Text('投递简历', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 立即沟通 button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('立即沟通'),
                    content: Text('即将与${job.company}的HR发起聊天'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('确定'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.systemGrey5,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chat_bubble_fill, size: 18, color: CupertinoColors.activeBlue),
                  SizedBox(width: 6),
                  Text('立即沟通', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyJob(BuildContext context) {
    VerificationService.checkVerification(
      context,
      () {
        showCupertinoModalPopup(
          context: context,
          builder: (ctx) => CupertinoActionSheet(
            title: const Text('投递简历'),
            message: Text('确认使用您的简历投递${job.company}的「${job.name}」职位吗？'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _submitApply(context);
                },
                child: const Text('投递简历'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const JobsResumePage()),
                  );
                },
                child: const Text('编辑简历'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
          ),
        );
      },
      message: '投递简历需要完成实名认证，请先进行认证。',
    );
  }

  void _submitApply(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('投递成功'),
        content: Text('简历已成功投递至${job.company}。\n\nHR将会在1-3个工作日内查看您的简历。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
