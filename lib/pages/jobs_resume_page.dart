import 'package:flutter/cupertino.dart';

class JobsResumePage extends StatefulWidget {
  const JobsResumePage({super.key});
  @override
  State<JobsResumePage> createState() => _JobsResumePageState();
}

class _JobsResumePageState extends State<JobsResumePage> {
  bool _editing = false;
  final _nameController = TextEditingController(text: '张三');
  String _gender = '男';
  final _ageController = TextEditingController(text: '28');
  final _phoneController = TextEditingController(text: '13800001234');
  final _schoolController = TextEditingController(text: '南京大学');
  final _majorController = TextEditingController(text: '计算机科学与技术');
  String _eduLevel = '本科';
  final _eduTimeController = TextEditingController(text: '2016-2020');
  final _workCompanyController = TextEditingController(text: '智云科技');
  final _workTitleController = TextEditingController(text: '前端开发工程师');
  final _workTimeController = TextEditingController(text: '2020-至今');
  final _workDescController = TextEditingController(text: '负责公司核心产品前端架构设计与开发，主导了3个大型项目的技术方案落地。');
  final _skillsController = TextEditingController(text: 'Flutter, React, TypeScript, Node.js');

  static const _genders = ['男', '女'];
  static const _eduLevels = ['高中', '大专', '本科', '硕士', '博士'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _majorController.dispose();
    _eduTimeController.dispose();
    _workCompanyController.dispose();
    _workTitleController.dispose();
    _workTimeController.dispose();
    _workDescController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的简历'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _editing = !_editing),
          child: Text(_editing ? '保存' : '编辑', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection('个人信息', children: [
                _buildField('姓名', _nameController),
                const SizedBox(height: 12),
                _buildGenderRow(),
                const SizedBox(height: 12),
                _buildField('年龄', _ageController, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildField('手机号', _phoneController, keyboardType: TextInputType.phone),
              ]),
              const SizedBox(height: 16),
              _buildSection('教育经历', children: [
                _buildField('学校', _schoolController),
                const SizedBox(height: 12),
                _buildField('专业', _majorController),
                const SizedBox(height: 12),
                _buildEduLevelRow(),
                const SizedBox(height: 12),
                _buildField('就读时间', _eduTimeController, placeholder: '如：2016-2020'),
              ]),
              const SizedBox(height: 16),
              _buildSection('工作经历', children: [
                _buildField('公司', _workCompanyController),
                const SizedBox(height: 12),
                _buildField('职位', _workTitleController),
                const SizedBox(height: 12),
                _buildField('工作时间', _workTimeController, placeholder: '如：2020-至今'),
                const SizedBox(height: 12),
                _buildField('工作描述', _workDescController, maxLines: 3),
              ]),
              const SizedBox(height: 16),
              _buildSection('技能标签', children: [
                _buildField('技能（逗号分隔）', _skillsController, placeholder: '如：Flutter, React, Python'),
              ]),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _buildField(String label, TextEditingController controller, {String? placeholder, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: placeholder,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    style: const TextStyle(fontSize: 15),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : (placeholder ?? '未填写'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: controller.text.isNotEmpty ? CupertinoColors.black : CupertinoColors.systemGrey,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGenderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 72,
          child: Text('性别', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _gender,
                    backgroundColor: const Color(0xFFF2F2F7),
                    thumbColor: CupertinoColors.white,
                    onValueChanged: (v) { if (v != null) setState(() => _gender = v); },
                    children: Map.fromEntries(_genders.map((g) => MapEntry(g, Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(g, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    )))),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(_gender, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
        ),
      ],
    );
  }

  Widget _buildEduLevelRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 72,
          child: Text('学历', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _eduLevel,
                    backgroundColor: const Color(0xFFF2F2F7),
                    thumbColor: CupertinoColors.white,
                    onValueChanged: (v) { if (v != null) setState(() => _eduLevel = v); },
                    children: Map.fromEntries(_eduLevels.map((e) => MapEntry(e, Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )))),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(_eduLevel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
        ),
      ],
    );
  }
}
