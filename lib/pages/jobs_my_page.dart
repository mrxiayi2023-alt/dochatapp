import 'package:flutter/cupertino.dart';
import 'jobs_page.dart';
import 'jobs_publish_page.dart';
import 'jobs_resume_page.dart';
import 'jobs_detail_page.dart';
import 'jobs_interview_page.dart';
import '../services/verification_service.dart';

class JobsMyPage extends StatefulWidget {
  final String identity; // 'personal' or 'company'
  const JobsMyPage({super.key, required this.identity});

  @override
  State<JobsMyPage> createState() => _JobsMyPageState();
}

class _JobsMyPageState extends State<JobsMyPage> {
  int _tabIndex = 0;

  static const _personalTabs = ['我的简历', '我的收藏', '面试通知'];
  static const _companyTabs = ['发布职位', '收到的简历', '面试管理'];

  List<String> get _tabs => widget.identity == 'personal' ? _personalTabs : _companyTabs;
  bool get isCompany => widget.identity == 'company';
  bool get isPersonal => widget.identity == 'personal';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(isCompany ? '企业中心' : '个人中心'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tab selector
            Container(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _tabIndex,
                  backgroundColor: CupertinoColors.systemGrey6,
                  thumbColor: CupertinoColors.white,
                  onValueChanged: (v) { if (v != null) setState(() => _tabIndex = v); },
                  children: Map.fromEntries(
                    List.generate(_tabs.length, (i) => MapEntry(i, Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(_tabs[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ))),
                  ),
                ),
              ),
            ),
            // Tab content
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: isCompany ? _buildCompanyTabs() : _buildPersonalTabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════ Personal tabs ══════════════
  List<Widget> _buildPersonalTabs() => [
    _buildResumeTab(),
    _buildFavoritesTab(),
    _buildInterviewTab(),
  ];

  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const JobsResumePage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(CupertinoIcons.doc_text, size: 24, color: CupertinoColors.activeBlue),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('张三', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('南京大学 · 计算机科学与技术 · 本科', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                        SizedBox(height: 2),
                        Text('Flutter, React, TypeScript, Node.js', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2)),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const JobsResumePage()),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('编辑简历', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favs = demoJobs.where((j) => jobFavIds.contains(j.id)).toList();
    if (favs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.heart, size: 48, color: CupertinoColors.systemGrey3),
            SizedBox(height: 12),
            Text('暂无收藏职位', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
            SizedBox(height: 6),
            Text('在职位列表中点击❤️即可收藏', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favs.length,
      itemBuilder: (_, i) => _buildFavCard(favs[i]),
    );
  }

  Widget _buildFavCard(JobItem job) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => JobsDetailPage(job: job)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(job.company, style: const TextStyle(fontSize: 13, color: CupertinoColors.black)),
                      const SizedBox(width: 8),
                      Text(job.location, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('¥${job.salary}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewTab() {
    final interviews = _demoInterviews;
    if (interviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.calendar, size: 48, color: CupertinoColors.systemGrey3),
            SizedBox(height: 12),
            Text('暂无面试通知', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: interviews.length,
      itemBuilder: (_, i) => _buildInterviewCard(interviews[i]),
    );
  }

  // ══════════════ Company tabs ══════════════
  List<Widget> _buildCompanyTabs() => [
    _buildPublishTab(),
    _buildReceivedResumesTab(),
    _buildManageInterviewTab(),
  ];

  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              VerificationService.checkCompanyVerify(
                context,
                () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const JobsPublishPage()),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.plus_circle_fill, size: 24, color: CupertinoColors.activeBlue),
                  SizedBox(width: 10),
                  Text('发布新职位', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('已发布的职位', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...demoJobs.take(2).map((j) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag(j.experience),
                          const SizedBox(width: 6),
                          _buildTag(j.education),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('¥${j.salary} · ${j.location}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('发布中', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CupertinoColors.systemGreen)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
    );
  }

  Widget _buildReceivedResumesTab() {
    final applications = _demoApplications;
    if (applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3),
            SizedBox(height: 12),
            Text('暂无收到的简历', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (_, i) {
        final a = applications[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(a.name.substring(0, 1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.systemGrey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(a.jobName, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${a.school} · ${a.major}', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 4),
                    Text(a.time, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3)),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                color: CupertinoColors.activeBlue,
                child: const Text('查看', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text('${a.name}的简历'),
                      content: Text('${a.school} · ${a.major}\n${a.skills}\n\n投递职位：${a.jobName}\n投递时间：${a.time}'),
                      actions: [
                        CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('关闭')),
                        CupertinoDialogAction(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => const JobsInterviewPage(mode: 'company')),
                            );
                          },
                          child: const Text('邀请面试'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageInterviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CupertinoButton(
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const JobsInterviewPage(mode: 'company')),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          color: CupertinoColors.white,
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 22, color: CupertinoColors.activeBlue),
              SizedBox(width: 12),
              Expanded(child: Text('面试管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.black))),
              Text('3条待确认', style: TextStyle(fontSize: 13, color: CupertinoColors.systemOrange)),
              SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const JobsPublishPage()),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          color: CupertinoColors.white,
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(CupertinoIcons.plus_circle, size: 22, color: CupertinoColors.systemGreen),
              SizedBox(width: 12),
              Expanded(child: Text('快速发布职位', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.black))),
              Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════ Demo data ══════════════

// Interview demo data
class _InterviewItem {
  final String jobName;
  final String company;
  final String time;
  final String status; // pending / accepted / rejected
  final String contact;
  final String note;
  const _InterviewItem({
    required this.jobName,
    required this.company,
    required this.time,
    required this.status,
    this.contact = '',
    this.note = '',
  });
}

const _demoInterviews = [
  _InterviewItem(jobName: '前端开发工程师', company: '智云科技', time: '2026-07-01 14:00', status: 'pending', contact: '张经理 13800001111', note: '请携带简历和作品集，提前10分钟到达。'),
  _InterviewItem(jobName: 'Java后端开发', company: '星辰软件', time: '2026-07-03 10:00', status: 'accepted', contact: '李HR 13800002222', note: '线上面试，请提前测试网络。'),
  _InterviewItem(jobName: '产品经理', company: '未来科技', time: '2026-06-28 15:00', status: 'rejected'),
];

// Application demo data
class _ApplicationItem {
  final String name;
  final String jobName;
  final String school;
  final String major;
  final String skills;
  final String time;
  const _ApplicationItem({
    required this.name,
    required this.jobName,
    required this.school,
    required this.major,
    required this.skills,
    required this.time,
  });
}

const _demoApplications = [
  _ApplicationItem(name: '李明', jobName: '前端开发工程师', school: '南京大学', major: '软件工程', skills: 'React, Vue, TypeScript', time: '2026-06-20'),
  _ApplicationItem(name: '王芳', jobName: 'UI设计师', school: '中国美院', major: '视觉传达', skills: 'Figma, Sketch, PS', time: '2026-06-19'),
  _ApplicationItem(name: '赵强', jobName: 'Java后端开发', school: '浙江大学', major: '计算机科学', skills: 'Java, Spring, MySQL', time: '2026-06-18'),
];

// Build the interview card used by the personal interview tab
Widget _buildInterviewCard(_InterviewItem item) {
  Color statusColor;
  String statusText;
  switch (item.status) {
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
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.jobName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(item.company, style: const TextStyle(fontSize: 14, color: CupertinoColors.black)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(CupertinoIcons.clock, size: 12, color: CupertinoColors.systemGrey),
            const SizedBox(width: 4),
            Text(item.time, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
          ],
        ),
        if (item.status == 'pending') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: CupertinoColors.systemGreen,
                  child: const Text('接受', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: CupertinoColors.systemGrey5,
                  child: const Text('拒绝', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.destructiveRed)),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
