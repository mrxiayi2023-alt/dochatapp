import 'package:flutter/cupertino.dart';

class JobsResumePreviewPage extends StatelessWidget {
  const JobsResumePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('简历预览', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompletenessCard(),
              const SizedBox(height: 16),
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              _buildJobPrefCard(),
              const SizedBox(height: 16),
              _buildEduCard(),
              const SizedBox(height: 16),
              _buildWorkCard(),
              const SizedBox(height: 16),
              _buildSkillsCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletenessCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF357ABD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal_fill, size: 20, color: CupertinoColors.white),
              SizedBox(width: 8),
              Text('简历完整度', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CupertinoColors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: CupertinoColors.white.withValues(alpha: 0.3),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.85,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('85%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CupertinoColors.white)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('建议完善：工作经历可增加更多详情', style: TextStyle(fontSize: 12, color: CupertinoColors.white)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildSectionCard('基本信息', [
      _buildInfoRow('姓名', '张三'),
      _buildInfoRow('性别', '男'),
      _buildInfoRow('出生年月', '1998-05-20'),
      _buildInfoRow('当前状态', '在职'),
      _buildInfoRow('手机号', '13800001234'),
      _buildInfoRow('邮箱', 'zhangsan@example.com'),
      _buildInfoRow('籍贯', '江苏省扬州市'),
      _buildInfoRow('现居地', '江苏省扬州市邗江区'),
    ]);
  }

  Widget _buildJobPrefCard() {
    return _buildSectionCard('求职意向', [
      _buildInfoRow('期望职位', '前端开发工程师'),
      _buildInfoRow('期望行业', '互联网'),
      _buildInfoRow('期望薪资', '15K-25K'),
      _buildInfoRow('工作城市', '扬州市'),
      _buildInfoRow('工作性质', '全职'),
      _buildInfoRow('到岗时间', '随时'),
    ]);
  }

  Widget _buildEduCard() {
    return _buildSectionCard('教育经历', [
      _buildEduBlock('南京大学', '计算机科学与技术', '本科', '2016-2020'),
    ]);
  }

  Widget _buildEduBlock(String school, String major, String degree, String period) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(school, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('$major · $degree', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 2),
          Text(period, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2)),
        ],
      ),
    );
  }

  Widget _buildWorkCard() {
    return _buildSectionCard('工作经历', [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('智云科技', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            const Text('前端开发工程师', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            const Text('2020-至今', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2)),
            const SizedBox(height: 4),
            const Text('负责公司核心产品前端架构设计与开发，主导了3个大型项目的技术方案落地，团队效率提升40%。', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    ]);
  }

  Widget _buildSkillsCard() {
    return _buildSectionCard('技能与优势', [
      Wrap(
        spacing: 8, runSpacing: 8,
        children: const [
          _SkillChip('Flutter'),
          _SkillChip('React'),
          _SkillChip('TypeScript'),
          _SkillChip('Node.js'),
        ],
      ),
      const SizedBox(height: 12),
      const Text('个人优势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('具备出色的前端架构能力，擅长复杂交互场景的技术方案设计，有良好的团队协作和沟通能力。', style: TextStyle(fontSize: 14, height: 1.6, color: CupertinoColors.systemGrey)),
    ]);
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String text;
  const _SkillChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.activeBlue)),
    );
  }
}
