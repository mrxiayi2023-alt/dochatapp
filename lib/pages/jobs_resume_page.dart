import 'package:flutter/cupertino.dart';
import '../services/verification_service.dart';
import '../widgets/region_picker.dart';
import 'jobs_page.dart';

class _EduEntry {
  String school;
  String major;
  String degree;
  String period;
  _EduEntry({required this.school, required this.major, required this.degree, required this.period});
}

class _WorkEntry {
  String company;
  String title;
  String period;
  String description;
  _WorkEntry({required this.company, required this.title, required this.period, required this.description});
}

class JobsResumePage extends StatefulWidget {
  const JobsResumePage({super.key});
  @override
  State<JobsResumePage> createState() => _JobsResumePageState();
}

class _JobsResumePageState extends State<JobsResumePage> {
  bool _editing = false;
  String _visibility = '公开'; // 公开 / 隐藏 / 仅投递可见
  static const _visibilities = ['公开', '隐藏', '仅投递可见'];

  // Basic info
  final _nameCtrl = TextEditingController(text: '张三');
  String _gender = '男';
  DateTime _birthDate = DateTime(1998, 5, 20);
  final _phoneCtrl = TextEditingController(text: '13800001234');
  final _emailCtrl = TextEditingController(text: 'zhangsan@example.com');
  RegionSelection? _nativeRegion;
  RegionSelection? _liveRegion;
  String _currentStatus = '在职'; // 在职/待业

  // Job preferences
  final _desiredJobCtrl = TextEditingController(text: '前端开发工程师');
  String _desiredIndustry = '互联网';
  final _desiredSalaryCtrl = TextEditingController(text: '15K-25K');
  RegionSelection? _workCityRegion;
  String _workType = '全职';
  String _availableTime = '随时'; // 到岗时间：随时/一周内/两周内/一个月内

  // Education
  final List<_EduEntry> _eduList = [
    _EduEntry(school: '南京大学', major: '计算机科学与技术', degree: '本科', period: '2016-2020'),
  ];

  // Work experience
  final List<_WorkEntry> _workList = [
    _WorkEntry(company: '智云科技', title: '前端开发工程师', period: '2020-至今', description: '负责公司核心产品前端架构设计与开发，主导了3个大型项目的技术方案落地，团队效率提升40%。'),
  ];

  // Skills
  final List<String> _skills = ['Flutter', 'React', 'TypeScript', 'Node.js'];
  final _skillInputCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController(text: '具备出色的前端架构能力，擅长复杂交互场景的技术方案设计，有良好的团队协作和沟通能力。');

  static const _genders = ['男', '女'];
  static const _statusOptions = ['在职', '待业'];
  static const _degrees = ['大专', '本科', '硕士', '博士'];
  static const _workTypes = ['全职', '兼职', '实习'];
  static const _availableOptions = ['随时', '一周内', '两周内', '一个月内'];
  static const _industries = [
    '互联网', '电子商务', '金融', '教育', '医疗', '制造',
    '房地产', '物流', '餐饮', '零售', '媒体', '法律',
    '咨询', '能源', '农业', '建筑', '交通', '旅游', '其他',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _desiredJobCtrl.dispose(); _desiredSalaryCtrl.dispose();
    _skillInputCtrl.dispose(); _strengthCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的简历'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            VerificationService.checkVerification(
              context,
              () {
                setState(() => _editing = !_editing);
                // 保存简历 → 标记简历已设置
                if (!_editing) hasResume = true;
              },
              message: '编辑简历需要完成实名认证，请先进行认证。',
            );
          },
          child: Text(_editing ? '保存' : '编辑', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 16),
              _buildVisibilityCard(),
              const SizedBox(height: 16),
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildJobPrefSection(),
              const SizedBox(height: 16),
              _buildEduSection(),
              const SizedBox(height: 16),
              _buildWorkSection(),
              const SizedBox(height: 16),
              _buildSkillsSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ Photo ═══
  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _editing ? _showPhotoDialog() : null,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: CupertinoColors.systemGrey4, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(CupertinoIcons.person_fill, size: 36, color: CupertinoColors.systemGrey3),
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
              onPressed: _showPhotoDialog,
              child: const Text('添加照片', style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue)),
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('上传照片'),
        content: const Text('请上传清晰的证件照。\n\n当前为演示模式，图片功能暂不可用。'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  Widget _buildVisibilityCard() {
    return _buildCard('简历状态', [
      if (_editing)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(10)),
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: _visibility,
            backgroundColor: const Color(0xFFF2F2F7),
            thumbColor: CupertinoColors.white,
            onValueChanged: (v) { if (v != null) setState(() => _visibility = v); },
            children: Map.fromEntries(_visibilities.map((o) => MapEntry(o, Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )))),
          ),
        )
      else ...[
        Row(
          children: [
            Icon(
              _visibility == '公开' ? CupertinoIcons.globe : _visibility == '隐藏' ? CupertinoIcons.eye_slash : CupertinoIcons.paperplane,
              size: 16, color: CupertinoColors.activeBlue,
            ),
            const SizedBox(width: 8),
            Text(_visibility, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text(
              _visibility == '公开' ? '(所有企业可见)' : _visibility == '隐藏' ? '(不对外展示)' : '(仅投递的企业可见)',
              style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ],
    ]);
  }

  // ═══ Basic info ═══
  Widget _buildBasicInfoSection() {
    return _buildCard('基本信息', [
      _buildFieldRow('姓名', _nameCtrl),
      const SizedBox(height: 10),
      _buildSegRow('性别', _genders, _gender, (v) => setState(() => _gender = v)),
      const SizedBox(height: 10),
      _buildDateRow('出生年月', _birthDate, (d) => setState(() => _birthDate = d)),
      const SizedBox(height: 10),
      _buildSegRow('当前状态', _statusOptions, _currentStatus, (v) => setState(() => _currentStatus = v)),
      const SizedBox(height: 10),
      _buildFieldRow('手机号', _phoneCtrl, keyboardType: TextInputType.phone),
      const SizedBox(height: 10),
      _buildFieldRow('邮箱', _emailCtrl, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 10),
      _buildRegionRow('籍贯', _nativeRegion, (r) => setState(() => _nativeRegion = r)),
      const SizedBox(height: 10),
      _buildRegionRow('现居地', _liveRegion, (r) => setState(() => _liveRegion = r)),
    ]);
  }

  // ═══ Job preferences ═══
  Widget _buildJobPrefSection() {
    return _buildCard('求职意向', [
      _buildFieldRow('期望职位', _desiredJobCtrl),
      const SizedBox(height: 10),
      _buildIndustryRow(),
      const SizedBox(height: 10),
      _buildFieldRow('期望薪资', _desiredSalaryCtrl, placeholder: '如：15K-25K'),
      const SizedBox(height: 10),
      _buildRegionRow('工作城市', _workCityRegion, (r) => setState(() => _workCityRegion = r)),
      const SizedBox(height: 10),
      _buildSegRow('工作性质', _workTypes, _workType, (v) => setState(() => _workType = v)),
      const SizedBox(height: 10),
      _buildAvailableRow(),
    ]);
  }

  Widget _buildAvailableRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 72, child: Text('到岗时间', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? GestureDetector(
                  onTap: () => _showAvailableSheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(child: Text(_availableTime, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                        const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey),
                      ],
                    ),
                  ),
                )
              : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_availableTime, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ),
      ],
    );
  }

  void _showAvailableSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择到岗时间'),
        actions: _availableOptions.map((opt) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() => _availableTime = opt);
            Navigator.of(ctx).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_availableTime == opt)
                const Icon(CupertinoIcons.checkmark, size: 18, color: CupertinoColors.activeBlue)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(opt, style: TextStyle(
                fontSize: 16,
                fontWeight: _availableTime == opt ? FontWeight.w600 : FontWeight.w400,
                color: _availableTime == opt ? CupertinoColors.activeBlue : CupertinoColors.black,
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

  // ═══ Education ═══
  Widget _buildEduSection() {
    return _buildCard('教育经历', [
      ..._eduList.asMap().entries.map((e) => _buildEduItem(e.key, e.value)),
      if (_editing)
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: CupertinoColors.systemGrey6,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.plus_circle, size: 18, color: CupertinoColors.activeBlue),
              SizedBox(width: 6),
              Text('添加教育经历', style: TextStyle(fontSize: 14, color: CupertinoColors.activeBlue)),
            ],
          ),
          onPressed: () => _showEduEditor(null),
        ),
    ]);
  }

  Widget _buildEduItem(int index, _EduEntry edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(edu.school, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${edu.major} · ${edu.degree}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                const SizedBox(height: 2),
                Text(edu.period, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2)),
              ],
            ),
          ),
          if (_editing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showEduEditor(index),
                  child: const Icon(CupertinoIcons.pencil, size: 18, color: CupertinoColors.activeBlue),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _eduList.removeAt(index)),
                  child: const Icon(CupertinoIcons.delete, size: 18, color: CupertinoColors.destructiveRed),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ═══ Work experience ═══
  Widget _buildWorkSection() {
    return _buildCard('工作经历', [
      ..._workList.asMap().entries.map((e) => _buildWorkItem(e.key, e.value)),
      if (_editing)
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: CupertinoColors.systemGrey6,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.plus_circle, size: 18, color: CupertinoColors.activeBlue),
              SizedBox(width: 6),
              Text('添加工作经历', style: TextStyle(fontSize: 14, color: CupertinoColors.activeBlue)),
            ],
          ),
          onPressed: () => _showWorkEditor(null),
        ),
    ]);
  }

  Widget _buildWorkItem(int index, _WorkEntry work) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(work.company, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(work.title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(work.period, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2)),
                if (work.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(work.description, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (_editing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showWorkEditor(index),
                  child: const Icon(CupertinoIcons.pencil, size: 18, color: CupertinoColors.activeBlue),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _workList.removeAt(index)),
                  child: const Icon(CupertinoIcons.delete, size: 18, color: CupertinoColors.destructiveRed),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ═══ Skills ═══
  Widget _buildSkillsSection() {
    return _buildCard('技能与优势', [
      if (_editing) ...[
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoTextField(
                  controller: _skillInputCtrl,
                  placeholder: '输入技能名称',
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              color: CupertinoColors.activeBlue,
              child: const Text('添加', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
              onPressed: () {
                final text = _skillInputCtrl.text.trim();
                if (text.isNotEmpty && !_skills.contains(text)) {
                  setState(() { _skills.add(text); _skillInputCtrl.clear(); });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
      if (_skills.isNotEmpty)
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _skills.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.activeBlue)),
                if (_editing) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _skills.remove(s)),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: CupertinoColors.systemGrey3),
                  ),
                ],
              ],
            ),
          )).toList(),
        )
      else
        const Text('暂无技能标签', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
      const SizedBox(height: 12),
      if (_editing)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoTextField(
            controller: _strengthCtrl,
            placeholder: '描述您的个人优势...',
            maxLines: 4,
            padding: const EdgeInsets.all(12),
            style: const TextStyle(fontSize: 14),
          ),
        )
      else ...[
        const Text('个人优势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(_strengthCtrl.text.isNotEmpty ? _strengthCtrl.text : '未填写', style: TextStyle(fontSize: 14, height: 1.6, color: _strengthCtrl.text.isNotEmpty ? CupertinoColors.black : CupertinoColors.systemGrey)),
      ],
    ]);
  }

  // ═══ Shared builders ═══
  Widget _buildCard(String title, List<Widget> children) {
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

  Widget _buildFieldRow(String label, TextEditingController ctrl, {String? placeholder, TextInputType keyboardType = TextInputType.text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? Container(
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                  child: CupertinoTextField(controller: ctrl, placeholder: placeholder, keyboardType: keyboardType, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), style: const TextStyle(fontSize: 15)),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(ctrl.text.isNotEmpty ? ctrl.text : (placeholder ?? '未填写'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ctrl.text.isNotEmpty ? CupertinoColors.black : CupertinoColors.systemGrey)),
                ),
        ),
      ],
    );
  }

  Widget _buildSegRow(String label, List<String> options, String selected, ValueChanged<String> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(10)),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: selected, backgroundColor: const Color(0xFFF2F2F7), thumbColor: CupertinoColors.white,
                    onValueChanged: (v) { if (v != null) onChanged(v); },
                    children: Map.fromEntries(options.map((o) => MapEntry(o, Padding(
                      padding: EdgeInsets.symmetric(horizontal: options.length > 3 ? 8.0 : 16.0, vertical: 8),
                      child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    )))),
                  ),
                )
              : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(selected, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ),
      ],
    );
  }

  Widget _buildDateRow(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? GestureDetector(
                  onTap: () => _showDatePicker(date, onChanged),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(child: Text(_formatDate(date), style: const TextStyle(fontSize: 15))),
                        const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey),
                      ],
                    ),
                  ),
                )
              : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_formatDate(date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ),
      ],
    );
  }

  Widget _buildRegionRow(String label, RegionSelection? region, ValueChanged<RegionSelection> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? GestureDetector(
                  onTap: () async {
                    final result = await RegionPicker.show(context, initial: region, maxDepth: 4);
                    if (result != null && context.mounted) onChanged(result);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(child: Text(region?.displayPath ?? '请选择', style: TextStyle(fontSize: 15, color: region != null ? CupertinoColors.black : CupertinoColors.systemGrey))),
                        const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey),
                      ],
                    ),
                  ),
                )
              : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(region?.displayPath ?? '未填写', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: region != null ? CupertinoColors.black : CupertinoColors.systemGrey))),
        ),
      ],
    );
  }

  Widget _buildIndustryRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 72, child: Text('期望行业', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? GestureDetector(
                  onTap: () => _showIndustrySheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(child: Text(_desiredIndustry, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                        const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.systemGrey),
                      ],
                    ),
                  ),
                )
              : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_desiredIndustry, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ),
      ],
    );
  }

  void _showIndustrySheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择期望行业'),
        actions: _industries.map((ind) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() => _desiredIndustry = ind);
            Navigator.of(ctx).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_desiredIndustry == ind)
                const Icon(CupertinoIcons.checkmark, size: 18, color: CupertinoColors.activeBlue)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(ind, style: TextStyle(
                fontSize: 16,
                fontWeight: _desiredIndustry == ind ? FontWeight.w600 : FontWeight.w400,
                color: _desiredIndustry == ind ? CupertinoColors.activeBlue : CupertinoColors.black,
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

  // ═══ Date picker ═══
  void _showDatePicker(DateTime initial, ValueChanged<DateTime> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('完成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumYear: 1960,
                maximumYear: 2010,
                onDateTimeChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ Edu editor dialog ═══
  void _showEduEditor(int? index) {
    final isEdit = index != null;
    final entry = isEdit ? _eduList[index] : _EduEntry(school: '', major: '', degree: '本科', period: '');
    final schoolCtrl = TextEditingController(text: entry.school);
    final majorCtrl = TextEditingController(text: entry.major);
    var degree = entry.degree;
    final periodCtrl = TextEditingController(text: entry.period);
    String? schoolError;
    String? majorError;
    String? periodError;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => CupertinoAlertDialog(
          title: Text(isEdit ? '编辑教育经历' : '添加教育经历'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(controller: schoolCtrl, placeholder: '学校名称', padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
                if (schoolError != null) Text(schoolError!, style: const TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed)),
                const SizedBox(height: 10),
                CupertinoTextField(controller: majorCtrl, placeholder: '专业名称', padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
                if (majorError != null) Text(majorError!, style: const TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(8)),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: degree, backgroundColor: CupertinoColors.systemGrey6, thumbColor: CupertinoColors.white,
                    onValueChanged: (v) { if (v != null) setModalState(() => degree = v); },
                    children: Map.fromEntries(_degrees.map((d) => MapEntry(d, Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )))),
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(controller: periodCtrl, placeholder: '如：2016-2020', padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
                if (periodError != null) Text(periodError!, style: const TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed)),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
            CupertinoDialogAction(onPressed: () {
              setModalState(() {
                schoolError = schoolCtrl.text.trim().isEmpty ? '请填写学校' : null;
                majorError = majorCtrl.text.trim().isEmpty ? '请填写专业' : null;
                periodError = periodCtrl.text.trim().isEmpty ? '请填写时间' : null;
              });
              if (schoolError != null || majorError != null || periodError != null) return;

              setState(() {
                final newEntry = _EduEntry(school: schoolCtrl.text.trim(), major: majorCtrl.text.trim(), degree: degree, period: periodCtrl.text.trim());
                if (isEdit) { _eduList[index] = newEntry; } else { _eduList.add(newEntry); }
              });
              Navigator.of(ctx).pop();
            }, child: const Text('确定')),
          ],
        ),
      ),
    );
  }

  // ═══ Work editor dialog ═══
  void _showWorkEditor(int? index) {
    final isEdit = index != null;
    final entry = isEdit ? _workList[index] : _WorkEntry(company: '', title: '', period: '', description: '');
    final companyCtrl = TextEditingController(text: entry.company);
    final titleCtrl = TextEditingController(text: entry.title);
    final periodCtrl = TextEditingController(text: entry.period);
    final descCtrl = TextEditingController(text: entry.description);
    String? companyError;
    String? titleError;
    String? periodError;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => CupertinoAlertDialog(
          title: Text(isEdit ? '编辑工作经历' : '添加工作经历'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(controller: companyCtrl, placeholder: '公司名称', padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
                if (companyError != null) Text(companyError!, style: const TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed)),
                const SizedBox(height: 10),
                CupertinoTextField(controller: titleCtrl, placeholder: '职位名称', padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
                if (titleError != null) Text(titleError!, style: const TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed)),
                const SizedBox(height: 10),
                CupertinoTextField(controller: periodCtrl, placeholder: '如：2020-至今', padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
                if (periodError != null) Text(periodError!, style: const TextStyle(fontSize: 11, color: CupertinoColors.destructiveRed)),
                const SizedBox(height: 10),
                CupertinoTextField(controller: descCtrl, placeholder: '工作描述', maxLines: 3, padding: const EdgeInsets.all(10), style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
            CupertinoDialogAction(onPressed: () {
              setModalState(() {
                companyError = companyCtrl.text.trim().isEmpty ? '请填写公司' : null;
                titleError = titleCtrl.text.trim().isEmpty ? '请填写职位' : null;
                periodError = periodCtrl.text.trim().isEmpty ? '请填写时间' : null;
              });
              if (companyError != null || titleError != null || periodError != null) return;

              setState(() {
                final newEntry = _WorkEntry(company: companyCtrl.text.trim(), title: titleCtrl.text.trim(), period: periodCtrl.text.trim(), description: descCtrl.text.trim());
                if (isEdit) { _workList[index] = newEntry; } else { _workList.add(newEntry); }
              });
              Navigator.of(ctx).pop();
            }, child: const Text('确定')),
          ],
        ),
      ),
    );
  }
}
