import 'package:flutter/cupertino.dart';
import 'jobs_detail_page.dart';

class JobItem {
  final String name;
  final String salary;
  final String company;
  final String location;
  final String experience;
  final String education;
  final String description;

  const JobItem({
    required this.name,
    required this.salary,
    required this.company,
    required this.location,
    required this.experience,
    required this.education,
    required this.description,
  });
}

const _demoJobs = [
  JobItem(name: '前端开发工程师', salary: '15-25K', company: '智云科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责公司Web前端产品的设计与开发。精通HTML/CSS/JavaScript，熟悉React或Vue框架，有移动端开发经验者优先。'),
  JobItem(name: 'Java后端开发', salary: '18-30K', company: '星辰软件', location: '扬州市', experience: '5-10年', education: '本科', description: '负责后端服务架构设计与核心模块开发。精通Java/Spring Boot，熟悉微服务架构，有高并发系统开发经验。'),
  JobItem(name: 'UI设计师', salary: '12-20K', company: '设计工坊', location: '扬州市', experience: '1-3年', education: '大专', description: '负责移动端和Web端产品的UI设计。精通Figma/Sketch，有良好的视觉设计感和用户体验思维。'),
  JobItem(name: '产品经理', salary: '20-35K', company: '未来科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责产品规划、需求分析与项目管理。具备出色的逻辑思维和沟通能力，有B端产品经验者优先。'),
  JobItem(name: '测试工程师', salary: '10-18K', company: '云测技术', location: '扬州市', experience: '1-3年', education: '大专', description: '负责软件产品的功能测试和自动化测试。熟悉测试流程和方法论，有自动化测试框架使用经验。'),
  JobItem(name: '运维工程师', salary: '15-22K', company: '智云科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责线上服务的运维保障和自动化运维平台建设。熟悉Linux系统，掌握Docker/K8s等容器技术。'),
];

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});
  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final _searchController = TextEditingController();
  String _selectedSalary = '';
  String _selectedExp = '';
  String _selectedEdu = '';

  List<JobItem> get _filtered {
    var list = _demoJobs;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((j) => j.name.contains(query) || j.company.contains(query)).toList();
    }
    return list;
  }

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
            largeTitle: const Text('电波直聘'),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterBar()),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: '搜索职位或公司',
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterBar() {
    final salaries = ['', '10K以下', '10-20K', '20-30K', '30K以上'];
    final exps = ['', '应届', '1-3年', '3-5年', '5年以上'];
    final edus = ['', '大专', '本科', '硕士', '不限'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChipGroup('薪资', salaries, _selectedSalary, (v) => setState(() => _selectedSalary = v)),
          const SizedBox(width: 8),
          _buildChipGroup('经验', exps, _selectedExp, (v) => setState(() => _selectedExp = v)),
          const SizedBox(width: 8),
          _buildChipGroup('学历', edus, _selectedEdu, (v) => setState(() => _selectedEdu = v)),
        ],
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
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  color: CupertinoColors.activeBlue,
                  pressedOpacity: 0.7,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Text('立即沟通', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
