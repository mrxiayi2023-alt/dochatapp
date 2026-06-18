import 'package:flutter/cupertino.dart';

class EscrowCreatePage extends StatefulWidget {
  const EscrowCreatePage({super.key});
  @override
  State<EscrowCreatePage> createState() => _EscrowCreatePageState();
}

class _EscrowCreatePageState extends State<EscrowCreatePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  int _depositRateIndex = 1;
  bool _installment = false;
  int _feePayer = 0;

  static const _depositRates = [0.05, 0.10, 0.15, 0.20];
  static const _depositLabels = ['5%', '10%', '15%', '20%'];
  static const _feeLabels = ['发起方', '接收方', '平摊'];

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _amountController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showToast('请输入有效的担保金额');
      return;
    }
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'amount': amount,
      'deposit_rate': _depositRates[_depositRateIndex],
      'counterparty_phone': _phoneController.text.trim(),
      'installment': _installment,
      'fee_payer': _feePayer,
    });
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.5,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(fontSize: 17)),
        ),
        middle: const Text('创建担保单', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection('担保事项', _buildTitleField()),
              const SizedBox(height: 16),
              _buildSection('担保金额', _buildAmountField()),
              const SizedBox(height: 16),
              _buildSection('押金比例', _buildDepositRateSelector()),
              const SizedBox(height: 16),
              _buildSection('对方手机号', _buildPhoneField()),
              const SizedBox(height: 16),
              _buildSection('付款方式', _buildInstallmentToggle()),
              const SizedBox(height: 16),
              _buildSection('服务费承担方', _buildFeePayerSelector()),
              const SizedBox(height: 32),
              CupertinoButton(
                onPressed: _canSubmit ? _submit : null,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                color: _canSubmit ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                pressedOpacity: 0.7,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '创建担保单',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _canSubmit ? CupertinoColors.white : CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return CupertinoTextField(
      controller: _titleController,
      placeholder: '请输入担保事项',
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 16),
      style: const TextStyle(fontSize: 16),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildAmountField() {
    return CupertinoTextField(
      controller: _amountController,
      placeholder: '请输入金额',
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 16),
      style: const TextStyle(fontSize: 16),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 14, right: 4),
        child: Text('¥', style: TextStyle(fontSize: 16, color: CupertinoColors.black)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildDepositRateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: CupertinoSegmentedControl<int>(
        groupValue: _depositRateIndex,
        selectedColor: CupertinoColors.activeBlue,
        borderColor: CupertinoColors.systemGrey4,
        padding: const EdgeInsets.all(2),
        onValueChanged: (v) => setState(() => _depositRateIndex = v),
        children: {
          for (int i = 0; i < _depositLabels.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(_depositLabels[i], style: const TextStyle(fontSize: 14)),
            ),
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return CupertinoTextField(
      controller: _phoneController,
      placeholder: '输入对方手机号',
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 16),
      style: const TextStyle(fontSize: 16),
      keyboardType: TextInputType.phone,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildInstallmentToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('分阶段付款', style: TextStyle(fontSize: 16)),
          CupertinoSwitch(
            value: _installment,
            activeTrackColor: CupertinoColors.activeBlue,
            onChanged: (v) => setState(() => _installment = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFeePayerSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: CupertinoSegmentedControl<int>(
        groupValue: _feePayer,
        selectedColor: CupertinoColors.activeBlue,
        borderColor: CupertinoColors.systemGrey4,
        padding: const EdgeInsets.all(2),
        onValueChanged: (v) => setState(() => _feePayer = v),
        children: {
          for (int i = 0; i < _feeLabels.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(_feeLabels[i], style: const TextStyle(fontSize: 14)),
            ),
        },
      ),
    );
  }
}
