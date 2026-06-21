import 'package:flutter/cupertino.dart';
import '../services/verification_service.dart';
import '../widgets/region_picker.dart';

class JobsPublishPage extends StatefulWidget {
  const JobsPublishPage({super.key});
  @override
  State<JobsPublishPage> createState() => _JobsPublishPageState();
}

class _JobsPublishPageState extends State<JobsPublishPage> {
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  RegionSelection? _selectedRegion;
  String _experience = '1-3年';
  String _education = '本科';
  final _companyController = TextEditingController();
  final _descController = TextEditingController();

  static const _experiences = ['应届', '1-3年', '3-5年', '5-10年', '不限'];
  static const _educations = ['大专', '本科', '硕士', '不限'];

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _companyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('发布职位'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('职位名称'),
              _buildTextField(_nameController, '请输入职位名称'),
              const SizedBox(height: 16),
              _buildSectionTitle('薪资范围'),
              _buildTextField(_salaryController, '如：15K-25K'),
              const SizedBox(height: 16),
              _buildSectionTitle('工作地点'),
              _buildRegionRow(),
              const SizedBox(height: 16),
              _buildSectionTitle('经验要求'),
              _buildSegmentedControl(_experiences, _experience, (v) => setState(() => _experience = v)),
              const SizedBox(height: 16),
              _buildSectionTitle('学历要求'),
              _buildSegmentedControl(_educations, _education, (v) => setState(() => _education = v)),
              const SizedBox(height: 16),
              _buildSectionTitle('公司名称'),
              _buildTextField(_companyController, '请输入公司名称'),
              const SizedBox(height: 16),
              _buildSectionTitle('职位描述'),
              _buildTextField(_descController, '请详细描述职位职责和要求...', maxLines: 5),
              const SizedBox(height: 24),
              _buildPublishButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        padding: const EdgeInsets.all(14),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildRegionRow() {
    return GestureDetector(
      onTap: () async {
        final result = await RegionPicker.show(context, initial: _selectedRegion, maxDepth: 4);
        if (result != null && context.mounted) {
          setState(() => _selectedRegion = result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedRegion?.displayPath ?? '请选择工作地点',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedRegion != null ? CupertinoColors.black : CupertinoColors.systemGrey,
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(List<String> options, String selected, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: selected,
        backgroundColor: CupertinoColors.systemGrey6,
        thumbColor: CupertinoColors.white,
        onValueChanged: (v) { if (v != null) onChanged(v); },
        children: Map.fromEntries(options.map((o) => MapEntry(o, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        )))),
      ),
    );
  }

  Widget _buildPublishButton() {
    return CupertinoButton(
      onPressed: _submitPublish,
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      color: CupertinoColors.activeBlue,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Text('发布', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
    );
  }

  void _submitPublish() {
    if (_nameController.text.trim().isEmpty) { _showAlert('请填写职位名称'); return; }
    if (_salaryController.text.trim().isEmpty) { _showAlert('请填写薪资范围'); return; }
    if (_selectedRegion == null) { _showAlert('请选择工作地点'); return; }
    if (_companyController.text.trim().isEmpty) { _showAlert('请填写公司名称'); return; }

    VerificationService.checkCompanyVerify(
      context,
      () => _doPublish(),
    );
  }

  void _doPublish() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('发布成功'),
        content: const Text('职位信息已发布，将展示在直聘列表中。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }
}
