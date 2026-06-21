import 'package:flutter/cupertino.dart';

class InterviewEntry {
  final String id;
  final String jobName;
  final String counterparty; // company name or applicant name
  final String time;
  String status; // pending / accepted / rejected
  final String contact;
  final String note;

  InterviewEntry({
    required this.id,
    required this.jobName,
    required this.counterparty,
    required this.time,
    this.status = 'pending',
    this.contact = '',
    this.note = '',
  });
}

// Demo interviews for personal mode (received by applicant)
List<InterviewEntry> _personalInterviews = [
  InterviewEntry(id: 'I001', jobName: '前端开发工程师', counterparty: '智云科技', time: '2026-07-01 14:00', status: 'pending', contact: '张经理 13800001111', note: '请携带简历和作品集，提前10分钟到达会议室302。'),
  InterviewEntry(id: 'I002', jobName: 'Java后端开发', counterparty: '星辰软件', time: '2026-07-03 10:00', status: 'accepted', contact: '李HR 13800002222', note: '线上面试，请提前下载腾讯会议并测试设备。'),
  InterviewEntry(id: 'I003', jobName: '产品经理', counterparty: '未来科技', time: '2026-06-28 15:00', status: 'rejected'),
];

// Demo interviews for company mode (sent by employer)
List<InterviewEntry> _companyInterviews = [
  InterviewEntry(id: 'C001', jobName: '前端开发工程师', counterparty: '李明', time: '2026-07-01 14:00', status: 'pending', contact: '李明 13900001111', note: '线下面试'),
  InterviewEntry(id: 'C002', jobName: 'UI设计师', counterparty: '王芳', time: '2026-07-02 10:00', status: 'accepted', contact: '王芳 13900002222', note: '线上视频面试'),
  InterviewEntry(id: 'C003', jobName: 'Java后端开发', counterparty: '赵强', time: '2026-06-30 15:00', status: 'pending', contact: '赵强 13900003333', note: '带作品演示'),
];

class JobsInterviewPage extends StatefulWidget {
  final String mode; // 'personal' or 'company'
  const JobsInterviewPage({super.key, required this.mode});

  @override
  State<JobsInterviewPage> createState() => _JobsInterviewPageState();
}

class _JobsInterviewPageState extends State<JobsInterviewPage> {
  late List<InterviewEntry> _interviews;

  bool get isCompany => widget.mode == 'company';

  @override
  void initState() {
    super.initState();
    _interviews = List.from(isCompany ? _companyInterviews : _personalInterviews);
  }

  void _updateStatus(InterviewEntry entry, String status) {
    setState(() {
      entry.status = status;
      // Also update the source list
      final source = isCompany ? _companyInterviews : _personalInterviews;
      final idx = source.indexWhere((e) => e.id == entry.id);
      if (idx != -1) source[idx].status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _interviews.where((e) => e.status == 'pending').toList();
    final done = _interviews.where((e) => e.status != 'pending').toList();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(isCompany ? '面试管理' : '面试通知'),
      ),
      child: SafeArea(
        child: _interviews.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.calendar, size: 48, color: CupertinoColors.systemGrey3),
                    SizedBox(height: 12),
                    Text('暂无面试', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pending.isNotEmpty) ...[
                    _buildSectionHeader('待确认 (${pending.length})'),
                    ...pending.map(_buildInterviewCard),
                  ],
                  if (done.isNotEmpty) ...[
                    _buildSectionHeader(isCompany ? '已处理' : '已完成'),
                    ...done.map(_buildInterviewCard),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CupertinoColors.systemGrey)),
    );
  }

  Widget _buildInterviewCard(InterviewEntry entry) {
    Color statusColor;
    String statusText;
    switch (entry.status) {
      case 'accepted':
        statusColor = CupertinoColors.systemGreen;
        statusText = '已接受';
        break;
      case 'rejected':
        statusColor = CupertinoColors.destructiveRed;
        statusText = '已拒绝';
        break;
      default:
        statusColor = CupertinoColors.systemOrange;
        statusText = '待确认';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: entry.status == 'pending'
            ? Border(left: BorderSide(color: statusColor, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.jobName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCompany ? CupertinoIcons.person : CupertinoIcons.building_2_fill,
                size: 14, color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                entry.counterparty,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.systemGrey),
              const SizedBox(width: 4),
              Text(entry.time, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            ],
          ),
          if (entry.status == 'accepted' && entry.contact.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('联系方式：${entry.contact}', style: const TextStyle(fontSize: 13)),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('备注：${entry.note}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                  ],
                ],
              ),
            ),
          ],
          if (entry.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: CupertinoColors.systemGreen,
                    child: const Text('接受', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                    onPressed: () => _updateStatus(entry, 'accepted'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: CupertinoColors.systemGrey5,
                    child: const Text('拒绝', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.destructiveRed)),
                    onPressed: () => _updateStatus(entry, 'rejected'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
