import 'package:flutter/cupertino.dart';
import 'jobs_detail_page.dart';
import 'jobs_my_page.dart';
import 'jobs_chat_page.dart';
import 'jobs_interview_page.dart';
import '../services/verification_service.dart';
import '../services/jobs_chat_service.dart';
import '../services/jobs_service.dart';
import '../widgets/region_picker.dart';

import '../widgets/industry_picker.dart';
import 'jobs_resume_page.dart';
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

/// Persisted identity — survives page rebuilds within the session
String? _persistedIdentity;

/// Whether the user has set up a resume (shared across pages)
bool hasResume = false;

/// Whether the user has set up a company profile (shared across pages)
bool hasCompanyProfile = false;

class _JobsPageState extends State<JobsPage> {
  final _searchController = TextEditingController();
  String _viewMode = _persistedIdentity ?? 'personal'; // 'personal' or 'company'

  // Filter states
  String _selectedEdu = '';
  String _selectedExp = '';
  String _selectedSalary = '';
  String _selectedJobType = '';
  String _selectedCompanySize = '';
  String _selectedAvailability = '';
  String _selectedExpectedSalary = '';
  String _selectedStatus = ''; // 当前状态筛选
  String _selectedIndustry = '';
  String _selectedFundingStage = '';

  // Region filters
  RegionSelection? _selectedWorkRegion;   // 个人：工作地点
  RegionSelection? _selectedLocationRegion; // 企业：所在地

  static const _eduOptions = ['不限', '高中', '中专', '大专', '本科', '硕士', '博士'];
  static const _expOptions = ['不限', '应届', '1-3年', '3-5年', '5-10年', '10年以上'];
  static const _salaryOptions = ['不限', '5K以下', '5-10K', '10-15K', '15-20K', '20-30K', '30-50K', '50K以上'];
  static const _jobTypeOptions = ['不限', '全职', '兼职', '实习', '外包'];
  static const _companySizeOptions = ['不限', '少于20人', '20-99人', '100-499人', '500-999人', '1000人以上'];
  static const _availabilityOptions = ['不限', '随时', '一周内', '两周内', '一个月内', '待定'];
  static const _statusOptions = ['不限', '在职', '待业'];
  static const _fundingStageOptions = ['不限', '未融资', '天使轮', 'A轮', 'B轮', 'C轮', 'D轮及以上', '已上市', '不需要融资'];
  static List<String> get _industryOptions => ['不限', ...industryCategories.map((c) => c.name)];

  @override
  void initState() {
    super.initState();
    JobsService.init();
  }

  bool get isCompanyView => _viewMode == 'company';

  bool _isFav(String id) => _jobFavIds.contains(id);

  void _toggleFav(String id) => setState(() {
    if (_jobFavIds.contains(id)) { _jobFavIds.remove(id); } else { _jobFavIds.add(id); }
  });

  List<JobItem> get _filtered {
    var list = JobsService.jobs.where((j) => !blockedCompanies.contains(j.company)).toList();
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((j) => j.name.contains(query) || j.company.contains(query)).toList();
    }
    if (_selectedEdu.isNotEmpty && _selectedEdu != '不限') {
      list = list.where((j) => j.education == _selectedEdu).toList();
    }
    if (_selectedExp.isNotEmpty && _selectedExp != '不限') {
      list = list.where((j) {
        if (_selectedExp == '应届') return j.experience.contains('应届') || j.experience == '1年以下';
        if (_selectedExp == '10年以上') return j.experience.contains('10年');
        return j.experience.contains(_selectedExp.replaceAll('年', ''));
      }).toList();
    }
    return list;
  }

  List<CandidateItem> get _filteredCandidates {
    var list = JobsService.candidates;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((c) => c.desiredJob.contains(query) || c.name.contains(query)).toList();
    }
    if (_selectedEdu.isNotEmpty && _selectedEdu != '不限') {
      list = list.where((c) => c.education == _selectedEdu).toList();
    }
    if (_selectedExp.isNotEmpty && _selectedExp != '不限') {
      list = list.where((c) {
        final expYear = int.tryParse(c.experience.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (_selectedExp == '应届') return expYear < 1;
        if (_selectedExp == '1-3年') return expYear >= 1 && expYear <= 3;
        if (_selectedExp == '3-5年') return expYear >= 3 && expYear <= 5;
        if (_selectedExp == '5-10年') return expYear >= 5 && expYear <= 10;
        if (_selectedExp == '10年以上') return expYear >= 10;
        return true;
      }).toList();
    }
    return list;
  }

  List<JobItem> get favorites => JobsService.jobs.where((j) => _jobFavIds.contains(j.id)).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showGuide = !isCompanyView && !hasResume && _filtered.isEmpty;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(isCompanyView ? '人才广场' : '电波直聘'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👤 切换按钮 — 弹出身份选择ActionSheet
                GestureDetector(
                  onTap: () => _showIdentitySheet(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Text('👤', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 8),
                // 📋 我的按钮 — 直接进入当前身份对应中心
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
                    child: const Text('📋', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterBar()),
          if (showGuide)
            SliverFillRemaining(hasScrollBody: false, child: _buildGuideSection())
          else if (isCompanyView)
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

  void _showIdentitySheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择身份'),
        message: const Text('切换查看模式'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _viewMode = 'personal';
                _persistedIdentity = 'personal';
              });
              // 无简历 → 进入个人中心编辑简历 → 保存后返回展示职位列表
              if (!hasResume) {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const JobsMyPage(identity: 'personal')),
                ).then((_) {
                  // 访问过个人中心即视为已设置
                  hasResume = true;
                });
              }
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
                const Text('👤 个人（找工作）', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _viewMode = 'company';
                _persistedIdentity = 'company';
              });
              // 无公司资料 → 进入企业中心填写资料 → 保存后返回展示候选人列表
              if (!hasCompanyProfile) {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const JobsMyPage(identity: 'company')),
                ).then((_) {
                  // 访问过企业中心即视为已设置
                  hasCompanyProfile = true;
                });
              }
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
                const Text('🏢 企业（找人才）', style: TextStyle(fontWeight: FontWeight.w600)),
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

  // -----------------------------------------------------------------------
  // Filter Bar
  // -----------------------------------------------------------------------

  Widget _buildFilterBar() {
    final chips = <Widget>[];

    if (isCompanyView) {
      chips.addAll([
        _buildRegionFilterChip('所在地', _selectedLocationRegion, (r) => setState(() => _selectedLocationRegion = r)),
        const SizedBox(width: 8),
        _buildFilterChip('学历', _selectedEdu, _eduOptions, (v) => setState(() => _selectedEdu = v)),
        const SizedBox(width: 8),
        _buildFilterChip('经验', _selectedExp, _expOptions, (v) => setState(() => _selectedExp = v)),
        const SizedBox(width: 8),
        _buildFilterChip('期望薪资', _selectedExpectedSalary, _salaryOptions, (v) => setState(() => _selectedExpectedSalary = v)),
        const SizedBox(width: 8),
        _buildFilterChip('到岗时间', _selectedAvailability, _availabilityOptions, (v) => setState(() => _selectedAvailability = v)),
        const SizedBox(width: 8),
        _buildFilterChip('当前状态', _selectedStatus, _statusOptions, (v) => setState(() => _selectedStatus = v)),
        const SizedBox(width: 8),
        _buildFilterChip('工作性质', _selectedJobType, _jobTypeOptions, (v) => setState(() => _selectedJobType = v)),
      ]);
    } else {
      chips.addAll([
        _buildRegionFilterChip('工作地点', _selectedWorkRegion, (r) => setState(() => _selectedWorkRegion = r)),
        const SizedBox(width: 8),
        _buildFilterChip('学历要求', _selectedEdu, _eduOptions, (v) => setState(() => _selectedEdu = v)),
        const SizedBox(width: 8),
        _buildFilterChip('经验要求', _selectedExp, _expOptions, (v) => setState(() => _selectedExp = v)),
        const SizedBox(width: 8),
        _buildFilterChip('薪资范围', _selectedSalary, _salaryOptions, (v) => setState(() => _selectedSalary = v)),
        const SizedBox(width: 8),
        _buildFilterChip('工作性质', _selectedJobType, _jobTypeOptions, (v) => setState(() => _selectedJobType = v)),
        const SizedBox(width: 8),
        _buildFilterChip('公司规模', _selectedCompanySize, _companySizeOptions, (v) => setState(() => _selectedCompanySize = v)),
        const SizedBox(width: 8),
        _buildFilterChip('行业', _selectedIndustry, _industryOptions, (v) => setState(() => _selectedIndustry = v)),
        const SizedBox(width: 8),
        _buildFilterChip('融资阶段', _selectedFundingStage, _fundingStageOptions, (v) => setState(() => _selectedFundingStage = v)),
      ]);
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options, ValueChanged<String> onChanged) {
    final isActive = selected.isNotEmpty && selected != '不限';
    return GestureDetector(
      onTap: () => _showOptionSheet(context, label, options, selected, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? CupertinoColors.activeBlue : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? selected : label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? CupertinoColors.white : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 2),
            if (isActive)
              GestureDetector(
                onTap: () => onChanged(''),
                child: const Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: CupertinoColors.white),
              )
            else
              const Icon(CupertinoIcons.chevron_down, size: 12, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionFilterChip(String label, RegionSelection? region, ValueChanged<RegionSelection?> onChanged) {
    final isActive = region != null;
    return GestureDetector(
      onTap: () async {
        final result = await RegionPicker.show(context, initial: region, maxDepth: 4);
        if (result != null && context.mounted) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? CupertinoColors.activeBlue : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? region.shortPath : label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? CupertinoColors.white : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 2),
            if (isActive)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: CupertinoColors.white),
              )
            else
              const Icon(CupertinoIcons.chevron_down, size: 12, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _showOptionSheet(BuildContext context, String title, List<String> options, String selected, ValueChanged<String> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('选择$title'),
        actions: options.map((option) => CupertinoActionSheetAction(
          onPressed: () {
            onChanged(option == '不限' ? '' : option);
            Navigator.of(ctx).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected == option || (option == '不限' && selected.isEmpty))
                const Icon(CupertinoIcons.checkmark, size: 18, color: CupertinoColors.activeBlue)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(option, style: TextStyle(
                fontSize: 16,
                fontWeight: selected == option || (option == '不限' && selected.isEmpty)
                    ? FontWeight.w600 : FontWeight.w400,
                color: selected == option || (option == '不限' && selected.isEmpty)
                    ? CupertinoColors.activeBlue : CupertinoColors.black,
              )),
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


  Widget _buildGuideSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text_search, size: 72, color: CupertinoColors.activeBlue.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            const Text(
              '欢迎使用电波直聘',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              '您还没有创建简历，创建简历后即可浏览职位并投递。',
              style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.activeBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const JobsResumePage()),
              ),
              child: const Text('去创建简历', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ],
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
