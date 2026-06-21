import 'package:flutter/cupertino.dart';
import '../services/verification_service.dart';
import '../widgets/region_picker.dart';

class JobsCompanyVerifyPage extends StatefulWidget {
  const JobsCompanyVerifyPage({super.key});
  @override
  State<JobsCompanyVerifyPage> createState() => _JobsCompanyVerifyPageState();
}

class _JobsCompanyVerifyPageState extends State<JobsCompanyVerifyPage> {
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _legalPersonController = TextEditingController();
  RegionSelection? _selectedRegion;

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _legalPersonController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (VerificationService.companyVerifyStatus) {
      case 'pending': return '审核中';
      case 'verified': return '已认证';
      default: return '未认证';
    }
  }

  Color get _statusColor {
    switch (VerificationService.companyVerifyStatus) {
      case 'pending': return CupertinoColors.systemOrange;
      case 'verified': return CupertinoColors.systemGreen;
      default: return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = VerificationService.isCompanyVerified;
    final isPending = VerificationService.companyVerifyStatus == 'pending';

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('企业认证'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVerified
                          ? CupertinoIcons.checkmark_seal_fill
                          : isPending
                              ? CupertinoIcons.clock
                              : CupertinoIcons.exclamationmark_circle,
                      size: 20, color: _statusColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '认证状态：$_statusLabel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isVerified) ...[
                _buildSectionTitle('企业名称'),
                _buildTextField(_nameController, '请输入企业全称'),
                const SizedBox(height: 16),
                _buildSectionTitle('营业执照号'),
                _buildTextField(_licenseController, '请输入统一社会信用代码'),
                const SizedBox(height: 16),
                _buildSectionTitle('法人姓名'),
                _buildTextField(_legalPersonController, '请输入法定代表人姓名'),
                const SizedBox(height: 16),
                _buildSectionTitle('办公地址'),
                _buildRegionRow(),
                const SizedBox(height: 16),
                _buildSectionTitle('营业执照'),
                _buildLicenseUpload(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(CupertinoIcons.checkmark_seal_fill, size: 48, color: CupertinoColors.systemGreen),
                      SizedBox(height: 12),
                      Text('企业认证已完成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('您现在可以发布职位了', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ),
              ],
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

  Widget _buildTextField(TextEditingController controller, String placeholder) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
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
                _selectedRegion?.displayPath ?? '请选择办公地址',
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

  Widget _buildLicenseUpload() {
    return GestureDetector(
      onTap: () => showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('上传营业执照'),
          content: const Text('请上传清晰的营业执照照片。\n\n当前为演示模式，图片功能暂不可用。'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: const Column(
          children: [
            Icon(CupertinoIcons.doc, size: 32, color: CupertinoColors.systemGrey3),
            SizedBox(height: 8),
            Text('上传营业执照照片', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return CupertinoButton(
      onPressed: _submitVerify,
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      color: CupertinoColors.activeBlue,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Text('提交认证', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
    );
  }

  void _submitVerify() {
    if (_nameController.text.trim().isEmpty) { _showAlert('请填写企业名称'); return; }
    if (_licenseController.text.trim().isEmpty) { _showAlert('请填写营业执照号'); return; }
    if (_legalPersonController.text.trim().isEmpty) { _showAlert('请填写法人姓名'); return; }

    setState(() => VerificationService.companyVerifyStatus = 'pending');

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提交成功'),
        content: const Text('企业认证信息已提交，1-2个工作日内完成审核。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => VerificationService.companyVerifyStatus = 'verified');
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
