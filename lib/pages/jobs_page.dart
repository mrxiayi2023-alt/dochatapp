import 'package:flutter/cupertino.dart';
import 'jobs_detail_page.dart';
import 'jobs_my_page.dart';
import 'jobs_chat_page.dart';
import 'jobs_interview_page.dart';
import '../services/verification_service.dart';
import '../services/jobs_chat_service.dart';

class JobItem {
  final String id;
  final String name;
  final String salary;
  final String company;
  final String location;
  final String experience;
  final String education;
  final String description;

  const JobItem({
    required this.id,
    required this.name,
    required this.salary,
    required this.company,
    required this.location,
    required this.experience,
    required this.education,
    required this.description,
  });
}

const demoJobs = [
  JobItem(id: 'J001', name: '前端开发工程师', salary: '15-25K', company: '智云科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责公司Web前端产品的设计与开发。精通HTML/CSS/JavaScript，熟悉React或Vue框架，有移动端开发经验者优先。'),
  JobItem(id: 'J002', name: 'Java后端开发', salary: '18-30K', company: '星辰软件', location: '扬州市', experience: '5-10年', education: '本科', description: '负责后端服务架构设计与核心模块开发。精通Java/Spring Boot，熟悉微服务架构，有高并发系统开发经验。'),
  JobItem(id: 'J003', name: 'UI设计师', salary: '12-20K', company: '设计工坊', location: '扬州市', experience: '1-3年', education: '大专', description: '负责移动端和Web端产品的UI设计。精通Figma/Sketch，有良好的视觉设计感和用户体验思维。'),
  JobItem(id: 'J004', name: '产品经理', salary: '20-35K', company: '未来科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责产品规划、需求分析与项目管理。具备出色的逻辑思维和沟通能力，有B端产品经验者优先。'),
  JobItem(id: 'J005', name: '测试工程师', salary: '10-18K', company: '云测技术', location: '扬州市', experience: '1-3年', education: '大专', description: '负责软件产品的功能测试和自动化测试。熟悉测试流程和方法论，有自动化测试框架使用经验。'),
  JobItem(id: 'J006', name: '运维工程师', salary: '15-22K', company: '智云科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责线上服务的运维保障和自动化运维平台建设。熟悉Linux系统，掌握Docker/K8s等容器技术。'),
];

// Candidate data for company view
class CandidateItem {
  final String id;
  final String name;
  final String desiredJob;
  final String desiredSalary;
  final String experience;
  final String education;
  final String skills;

  const CandidateItem({
    required this.id,
    required this.name,
    required this.desiredJob,
    required this.desiredSalary,
    required this.experience,
    required this.education,
    required this.skills,
  });
}

const demoCandidates = [
  CandidateItem(id: 'C001', name: '李明', desiredJob: '前端开发工程师', desiredSalary: '15-25K', experience: '4年', education: '本科', skills: 'React, Vue, Flutter'),
  CandidateItem(id: 'C002', name: '王芳', desiredJob: 'UI设计师', desiredSalary: '12-18K', experience: '3年', education: '本科', skills: 'Figma, Sketch, PS'),
  CandidateItem(id: 'C003', name: '赵强', desiredJob: 'Java后端开发', desiredSalary: '20-30K', experience: '6年', education: '硕士', skills: 'Java, Spring, MySQL'),
  CandidateItem(id: 'C004', name: '张伟', desiredJob: '产品经理', desiredSalary: '18-28K', experience: '4年', education: '本科', skills: 'Axure, 数据分析, SQL'),
  CandidateItem(id: 'C005', name: '陈丽', desiredJob: '测试工程师', desiredSalary: '12-18K', experience: '2年', education: '大专', skills: 'Selenium, JMeter, Python'),
  CandidateItem(id: 'C006', name: '刘洋', desiredJob: '运维工程师', desiredSalary: '18-25K', experience: '5年', education: '本科', skills: 'K8s, Docker, Linux'),
];

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});
  @override
  State<JobsPage> createState() => _JobsPageState();
}

// Shared favorites state (accessible from JobsMyPage)
final _jobFavIds = <String>{};
Set<String> get jobFavIds => _jobFavIds;

/// Blocked companies (shared across pages)
final blockedCompanies = <String>{};

class _JobsPageState extends State<JobsPage> {
  final _searchController = TextEditingController();
  String _selectedSalary = '';
  String _selectedExp = '';
  String _selectedEdu = '';
  String _selectedDistance = '';
  String _viewMode = 'personal'; // 'personal' or 'company'

  static const _salaryOptions = ['不限', '5K以下', '5-10K', '10-15K', '15-20K', '20-30K', '30-50K', '50K以上'];
  static const _distanceOptions = ['不限', '3km', '5km', '10km', '20km', '50km'];

  bool get isCompanyView => _viewMode == 'company';

  bool _isFav(String id) => _jobFavIds.contains(id);

  void _toggleFav(String id) => setState(() {
    if (_jobFavIds.contains(id)) { _jobFavIds.remove(id); } else { _jobFavIds.add(id); }
  });

  List<JobItem> get _filtered {
    var list = demoJobs.where((j) => !blockedCompanies.contains(j.company)).toList();
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((j) => j.name.contains(query) || j.company.contains(query)).toList();
    }
    return list;
  }

  List<CandidateItem> get _filteredCandidates {
    var list = demoCandidates;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((c) => c.desiredJob.contains(query) || c.name.contains(query)).toList();
    }
    return list;
  }

  List<JobItem> get favorites => demoJobs.where((j) => _jobFavIds.contains(j.id)).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(isCompanyView ? '人才广场' : '电波直聘'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showModeSheet(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isCompanyView ? CupertinoColors.systemTeal.withValues(alpha: 0.15) : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isCompanyView ? CupertinoIcons.search_circle : CupertinoIcons.briefcase,
                      size: 20,
                      color: isCompanyView ? CupertinoColors.systemTeal : CupertinoColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => JobsMyPage(identity: _viewMode)),
                  ),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(CupertinoIcons.person_crop_circle, size: 20, color: CupertinoColors.black),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterBar()),
          if (isCompanyView)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCandidateCard(_filteredCandidates[index]),
                childCount: _filteredCandidates.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildJobCard(_filtered[index]),
                childCount: _filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  void _showModeSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择视角'),
        message: const Text('切换查看模式'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _viewMode = 'personal');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _viewMode == 'personal' ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  size: 20,
                  color: _viewMode == 'personal' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey3,
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.person, size: 20, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                const Text('个人视角 · 找工作', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _viewMode = 'company');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _viewMode == 'company' ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  size: 20,
                  color: _viewMode == 'company' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey3,
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.building_2_fill, size: 20, color: CupertinoColors.systemTeal),
                const SizedBox(width: 8),
                const Text('企业视角 · 找人才', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: isCompanyView ? '搜索候选人、期望职位或技能' : '搜索职位或公司',
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterBar() {
    final exps = ['', '应届', '1-3年', '3-5年', '5年以上'];
    final edus = ['', '大专', '本科', '硕士', '不限'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (!isCompanyView)
            _buildSalaryChip(),
          if (!isCompanyView) const SizedBox(width: 8),
          if (!isCompanyView)
            _buildDistanceChip(),
          if (!isCompanyView) const SizedBox(width: 8),
          _buildChipGroup('经验', exps, _selectedExp, (v) => setState(() => _selectedExp = v)),
          const SizedBox(width: 8),
          _buildChipGroup('学历', edus, _selectedEdu, (v) => setState(() => _selectedEdu = v)),
        ],
      ),
    );
  }

  Widget _buildSalaryChip() {
    return GestureDetector(
      onTap: () => _showSalarySheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _selectedSalary.isNotEmpty ? CupertinoColors.activeBlue : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedSalary.isNotEmpty ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedSalary.isEmpty ? '薪资范围' : _selectedSalary,
              style: TextStyle(
                fontSize: 12,
                color: _selectedSalary.isNotEmpty ? CupertinoColors.white : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: _selectedSalary.isNotEmpty ? CupertinoColors.white : CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceChip() {
    return GestureDetector(
      onTap: () => _showDistanceSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _selectedDistance.isNotEmpty ? CupertinoColors.activeBlue : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedDistance.isNotEmpty ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedDistance.isEmpty ? '距离' : _selectedDistance,
              style: TextStyle(
                fontSize: 12,
                color: _selectedDistance.isNotEmpty ? CupertinoColors.white : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: _selectedDistance.isNotEmpty ? CupertinoColors.white : CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  void _showDistanceSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择距离范围'),
        actions: _distanceOptions.map((option) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() => _selectedDistance = option == '不限' ? '' : option);
            Navigator.of(ctx).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedDistance == option || (option == '不限' && _selectedDistance.isEmpty))
                const Icon(CupertinoIcons.checkmark, size: 18, color: CupertinoColors.activeBlue)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(option, style: const TextStyle(fontSize: 16)),
            ],
          ),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showSalarySheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择薪资范围'),
        actions: _salaryOptions.map((option) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() => _selectedSalary = option == '不限' ? '' : option);
            Navigator.of(ctx).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedSalary == option || (option == '不限' && _selectedSalary.isEmpty))
                const Icon(CupertinoIcons.checkmark, size: 18, color: CupertinoColors.activeBlue)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(option, style: const TextStyle(fontSize: 16)),
            ],
          ),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildChipGroup(String label, List<String> options, String selected, ValueChanged<String> onSelect) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ),
        const SizedBox(width: 4),
        ...options.where((o) => o.isNotEmpty).map((o) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => onSelect(selected == o ? '' : o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected == o ? CupertinoColors.activeBlue : CupertinoColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == o ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                ),
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontSize: 12,
                  color: selected == o ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildJobCard(JobItem job) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => JobsDetailPage(job: job)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    '¥${job.salary}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(job.company, style: const TextStyle(fontSize: 14, color: CupertinoColors.black)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·', style: TextStyle(color: CupertinoColors.systemGrey)),
                  ),
                  Text(job.location, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·', style: TextStyle(color: CupertinoColors.systemGrey)),
                  ),
                  Text(job.experience, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () {
                        VerificationService.checkVerification(
                          context,
                          () {
                            final channelKey = JobsChatService.channelKey('personal', job.company);
                            Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => JobsChatPage(
                                channelKey: channelKey,
                                title: job.company,
                                myId: 'personal',
                                peerName: job.company,
                              )),
                            );
                          },
                          message: '沟通需要完成实名认证，请先进行认证。',
                        );
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      color: CupertinoColors.activeBlue,
                      pressedOpacity: 0.7,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Text('立即沟通', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _toggleFav(job.id),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isFav(job.id) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        size: 20,
                        color: _isFav(job.id) ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateCard(CandidateItem candidate) {
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (ctx) => CupertinoActionSheet(
            title: Text(candidate.name),
            message: Text('${candidate.desiredJob} · ${candidate.desiredSalary}\n${candidate.experience} · ${candidate.education}\n技能：${candidate.skills}'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final channelKey = JobsChatService.channelKey('智云科技', candidate.name);
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => JobsChatPage(
                      channelKey: channelKey,
                      title: candidate.name,
                      myId: '智云科技',
                      peerName: candidate.name,
                    )),
                  );
                },
                child: const Text('立即沟通'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const JobsInterviewPage(mode: 'company')),
                  );
                },
                child: const Text('邀请面试'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(candidate.name.substring(0, 1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.systemGrey)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(candidate.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('在线', style: TextStyle(fontSize: 10, color: CupertinoColors.systemGreen, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(candidate.desiredJob, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(
                    '¥${candidate.desiredSalary}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTag(candidate.experience),
                  const SizedBox(width: 6),
                  _buildTag(candidate.education),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(candidate.skills, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
        ),
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
}
