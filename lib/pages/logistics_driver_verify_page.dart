import 'package:flutter/cupertino.dart';

enum VerifyStatus { unverified, pending, verified, rejected }

class LogisticsDriverVerifyPage extends StatefulWidget {
  const LogisticsDriverVerifyPage({super.key});
  @override
  State<LogisticsDriverVerifyPage> createState() => _LogisticsDriverVerifyPageState();
}

class _LogisticsDriverVerifyPageState extends State<LogisticsDriverVerifyPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '138****5678');
  final _idNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();

  String _vehicleType = '小面';
  VerifyStatus _status = VerifyStatus.unverified;
  bool _isSubmitting = false;

  static const _vehicleTypes = ['小面', '中面', '厢货', '平板', '冷藏'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('司机认证'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusBanner(),
              const SizedBox(height: 16),
              _buildSectionTitle('个人信息'),
              _buildCard(
                children: [
                  _buildInfoRow(label: '真实姓名', controller: _nameController, placeholder: '请输入真实姓名', enabled: _status == VerifyStatus.unverified),
                  const SizedBox(height: 12),
                  _buildInfoRow(label: '手机号码', controller: _phoneController, placeholder: '请输入手机号', enabled: false),
                  const SizedBox(height: 12),
                  _buildInfoRow(label: '身份证号', controller: _idNumberController, placeholder: '请输入18位身份证号', enabled: _status == VerifyStatus.unverified),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('驾驶证信息'),
              _buildCard(
                children: [
                  _buildInfoRow(label: '驾驶证号', controller: _licenseController, placeholder: '请输入驾驶证号', enabled: _status == VerifyStatus.unverified),
                  const SizedBox(height: 12),
                  _buildVehicleTypeRow(),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('车辆信息'),
              _buildCard(
                children: [
                  _buildInfoRow(label: '车牌号码', controller: _plateController, placeholder: '如：沪A·88888', enabled: _status == VerifyStatus.unverified),
                ],
              ),
              const SizedBox(height: 24),
              _buildActionArea(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    IconData icon;
    String text;
    Color color;

    switch (_status) {
      case VerifyStatus.unverified:
        icon = CupertinoIcons.doc_checkmark;
        text = '尚未认证 - 填写信息后提交审核';
        color = CupertinoColors.systemGrey;
      case VerifyStatus.pending:
        icon = CupertinoIcons.clock_fill;
        text = '审核中 - 预计1-2个工作日完成';
        color = CupertinoColors.systemOrange;
      case VerifyStatus.verified:
        icon = CupertinoIcons.check_mark_circled_solid;
        text = '认证通过 - 您可以开始接单了';
        color = CupertinoColors.systemGreen;
      case VerifyStatus.rejected:
        icon = CupertinoIcons.exclamationmark_circle_fill;
        text = '认证未通过 - 请修改信息重新提交';
        color = CupertinoColors.destructiveRed;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    switch (_status) {
      case VerifyStatus.unverified:
        return CupertinoButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          color: CupertinoColors.activeBlue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: _isSubmitting
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('提交认证', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
        );
      case VerifyStatus.pending:
        return CupertinoButton(
          onPressed: null,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          color: CupertinoColors.systemOrange.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Text('审核中...', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
        );
      case VerifyStatus.verified:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CupertinoColors.systemGreen.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.check_mark_circled_solid, size: 24, color: CupertinoColors.systemGreen),
              SizedBox(width: 8),
              Text('认证通过 ✓ 已获得接单资格', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.systemGreen)),
            ],
          ),
        );
      case VerifyStatus.rejected:
        return CupertinoButton(
          onPressed: _handleReSubmit,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          color: CupertinoColors.destructiveRed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Text('修改后重新提交', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
        );
    }
  }

  void _handleSubmit() {
    if (_nameController.text.trim().isEmpty) {
      _showToast('请填写真实姓名');
      return;
    }
    if (_idNumberController.text.trim().isEmpty) {
      _showToast('请填写身份证号');
      return;
    }
    if (_licenseController.text.trim().isEmpty) {
      _showToast('请填写驾驶证号');
      return;
    }
    if (_plateController.text.trim().isEmpty) {
      _showToast('请填写车牌号码');
      return;
    }
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _status = VerifyStatus.pending;
        });
        _showToast('认证信息已提交，等待审核...');
      }
    });
  }

  void _handleReSubmit() {
    setState(() => _status = VerifyStatus.unverified);
    _showToast('请修改信息后重新提交');
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow({required String label, required TextEditingController controller, required String placeholder, required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          placeholderStyle: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          style: const TextStyle(fontSize: 14),
          enabled: enabled,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('准驾车型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 8),
        Row(
          children: _vehicleTypes.map((type) {
            final isSelected = type == _vehicleType;
            final canSelect = _status == VerifyStatus.unverified;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: canSelect ? () => setState(() => _vehicleType = type) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? null : Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Text(
                      type,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? CupertinoColors.white : CupertinoColors.darkBackgroundGray,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
