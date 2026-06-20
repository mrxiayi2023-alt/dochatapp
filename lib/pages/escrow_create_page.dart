import 'package:flutter/cupertino.dart';
import '../services/verification_service.dart';
import 'contact_picker_page.dart';

class EscrowCreatePage extends StatefulWidget {
  const EscrowCreatePage({super.key});
  @override
  State<EscrowCreatePage> createState() => _EscrowCreatePageState();
}

class _EscrowCreatePageState extends State<EscrowCreatePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _termsController = TextEditingController();
  final _breachController = TextEditingController();
  int _breachRate = 5;
  bool _dateSelected = false;
  int _depositMode = 0; // 0=单向上押, 1=双向上押
  int _depositPayer = 0; // 0=发起方上押, 1=接收方上押 (仅单向上押时有效)
  bool _installment = false;
  int _phase1Percent = 40;
  int _phase2Percent = 30;
  int _feePayer = 0;
  String? _selectedContactName;
  String? _selectedContactPhone;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  int _selectedHour = 9;

  static const _depositLabels = ['单向上押', '双向上押'];
  static const _feeLabels = ['发起方', '接收方', '平摊'];

  int get _phase3Percent => 100 - _phase1Percent - _phase2Percent;

  String get _dateDisplay {
    return '$_selectedYear年$_selectedMonth月$_selectedDay日$_selectedHour时';
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _amountController.text.trim().isNotEmpty &&
      _selectedContactName != null;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedYear = tomorrow.year;
    _selectedMonth = tomorrow.month;
    _selectedDay = tomorrow.day;
    _selectedHour = 9;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _termsController.dispose();
    _breachController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    VerificationService.checkVerification(
      context,
      () {
        // 双向上押 或 单向上押+发起方上押：发起方必须先付押金
        if (_depositMode == 1 || (_depositMode == 0 && _depositPayer == 0)) {
          _showInitiatorPaymentSheet();
        } else {
          _doSubmit();
        }
      },
      message: '发起担保需要完成实名认证，请先进行认证。',
    );
  }

  void _showInitiatorPaymentSheet() {
    final label = _depositMode == 1 ? '双向上押' : '单向上押';
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('$label — 发起方支付押金'),
        message: const Text('发起方需先付清押金才能创建担保单'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showPaymentSimulation('支付宝');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.money_yen_circle, size: 18, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('支付宝支付'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showPaymentSimulation('微信支付');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.chat_bubble_text, size: 18, color: CupertinoColors.systemGreen),
                SizedBox(width: 8),
                Text('微信支付'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showPaymentSimulation(String method) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('$method支付'),
        content: const Text('支付功能即将上线，模拟支付成功。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _doSubmit();
            },
            child: const Text('确认支付'),
          ),
        ],
      ),
    );
  }

  void _doSubmit() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showToast('请输入有效的担保金额');
      return;
    }
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'amount': amount,
      'breach_rate': _breachRate / 100.0,
      'deposit_mode': _depositMode,
      'deposit_payer': _depositPayer,
      'initiator_paid': _depositMode == 1 || (_depositMode == 0 && _depositPayer == 0),
      'counterparty_name': _selectedContactName!,
      'counterparty_phone': _selectedContactPhone!,
      'installment': _installment,
      'phase1_percent': _installment ? _phase1Percent : null,
      'phase2_percent': _installment ? _phase2Percent : null,
      'phase3_percent': _installment ? _phase3Percent : null,
      'fee_payer': _feePayer,
      'terms': _termsController.text.trim(),
      'delivery_time': _dateDisplay,
      'breach': _breachController.text.trim(),
    });
  }

  Future<void> _openContactPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(builder: (_) => const ContactPickerPage()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedContactName = result['name'] as String?;
      _selectedContactPhone = result['phone'] as String?;
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
              _buildSection('担保条款', _buildTermsSection()),
              const SizedBox(height: 16),
              _buildSection('担保金额', _buildAmountSection()),
              const SizedBox(height: 16),
              _buildSection('选择对方', _buildContactSelector()),
              const SizedBox(height: 16),
              _buildSection('交付时间与违约金', _buildDeliveryAndBreachRow()),
              const SizedBox(height: 16),
              _buildSection('服务费承担方', _buildFeePayerSelector()),
              const SizedBox(height: 16),
              _buildSection('付款方式', _buildInstallmentSection()),
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
              const SizedBox(height: 8),
              Text(
                _depositMode == 0
                    ? (_depositPayer == 0 ? '发起方押金付清后订单方可生效' : '接收方押金付清后订单方可生效')
                    : '双方押金付清后订单方可生效',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3),
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

  Widget _buildAmountSection() {
    return Column(
      children: [
        // Amount input
        CupertinoTextField(
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
        ),
        _sectionDivider(),
        // Deposit mode
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: CupertinoSegmentedControl<int>(
            groupValue: _depositMode,
            selectedColor: CupertinoColors.activeBlue,
            borderColor: CupertinoColors.systemGrey4,
            padding: const EdgeInsets.all(2),
            onValueChanged: (v) => setState(() => _depositMode = v),
            children: {
              for (int i = 0; i < _depositLabels.length; i++)
                i: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(_depositLabels[i], style: const TextStyle(fontSize: 14)),
                ),
            },
          ),
        ),
        // Single deposit payer selector (ActionSheet style)
        if (_depositMode == 0) ...[
          _sectionDivider(),
          GestureDetector(
            onTap: _showDepositPayerSheet,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.person_crop_circle, size: 18, color: CupertinoColors.systemGrey2),
                  const SizedBox(width: 8),
                  Text(
                    _depositPayer == 0 ? '单向上押·发起方' : '单向上押·接收方',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey3),
                ],
              ),
            ),
          ),
        ],
        _sectionDivider(),
        // Payment method
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(CupertinoIcons.creditcard, size: 18, color: CupertinoColors.systemGrey2),
              const SizedBox(width: 8),
              const Text('押金支付', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showPaymentToast('支付宝'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.money_yen_circle, size: 16, color: CupertinoColors.systemBlue),
                      SizedBox(width: 4),
                      Text('支付宝', style: TextStyle(fontSize: 13, color: CupertinoColors.systemBlue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showPaymentToast('微信'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.chat_bubble_text, size: 16, color: CupertinoColors.systemGreen),
                      SizedBox(width: 4),
                      Text('微信支付', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGreen)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _sectionDivider(),
        // Deposit status preview
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_depositMode == 1 || _depositPayer == 0)
                _buildDepositStatusRow('发起方', false),
              if (_depositMode == 1 || _depositPayer == 1)
                _buildDepositStatusRow('接收方', false),
              const SizedBox(height: 6),
              Text(
                _depositMode == 0
                    ? (_depositPayer == 0 ? '发起方付清即可生效' : '接收方付清即可生效')
                    : '双方付清后方可生效',
                style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepositStatusRow(String role, bool paid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(role, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
        const SizedBox(width: 6),
        Text(paid ? '已付🟢' : '未付⚫',
            style: TextStyle(fontSize: 12, color: paid ? CupertinoColors.systemGreen : CupertinoColors.systemGrey2)),
      ],
    );
  }

  void _showDepositPayerSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择上押方'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _depositPayer = 0);
            },
            child: const Text('发起方上押'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _depositPayer = 1);
            },
            child: const Text('接收方上押'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showPaymentToast(String method) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('$method支付'),
        content: const Text('支付功能即将上线，敬请期待。'),
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

  Widget _sectionDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 14),
      color: CupertinoColors.systemGrey5,
    );
  }

  Widget _buildDeliveryAndBreachRow() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // Date button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                borderRadius: BorderRadius.circular(8),
                color: CupertinoColors.systemGrey6,
                pressedOpacity: 0.5,
                onPressed: _showDatePicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 14, color: CupertinoColors.activeBlue),
                    const SizedBox(width: 4),
                    Text(
                      _dateSelected ? _dateDisplay : '选择日期',
                      style: const TextStyle(fontSize: 14, color: CupertinoColors.activeBlue),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Breach rate stepper
              const Text('违约金 ', style: TextStyle(fontSize: 14, color: CupertinoColors.black)),
              GestureDetector(
                onTap: () {
                  if (_breachRate > 1) setState(() => _breachRate--);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _breachRate > 1
                        ? CupertinoColors.systemGrey4
                        : CupertinoColors.systemGrey6,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '−',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _breachRate > 1 ? CupertinoColors.black : CupertinoColors.systemGrey3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  '$_breachRate%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_breachRate < 20) setState(() => _breachRate++);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _breachRate < 20
                        ? CupertinoColors.systemGrey4
                        : CupertinoColors.systemGrey6,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _breachRate < 20 ? CupertinoColors.black : CupertinoColors.systemGrey3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 14, right: 14, bottom: 8),
          child: Text('不超过法定上限20%',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3)),
        ),
      ],
    );
  }

  Widget _buildContactSelector() {
    final hasSelection = _selectedContactName != null;
    return GestureDetector(
      onTap: _openContactPicker,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (hasSelection)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedContactName![0],
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              )
            else
              const Icon(CupertinoIcons.person_add, size: 22, color: CupertinoColors.systemGrey3),
            const SizedBox(width: 10),
            Expanded(
              child: hasSelection
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedContactName!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(_selectedContactPhone!,
                            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                      ],
                    )
                  : const Text('点击选择对方',
                      style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey3)),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentSection() {
    return Column(
      children: [
        // Toggle row
        Padding(
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
        ),
        // Phase pickers (visible when toggle is on)
        if (_installment) ...[
          _sectionDivider(),
          _buildPhaseRow(1, _phase1Percent, 1, 100, (v) {
            setState(() {
              _phase1Percent = v;
              if (_phase1Percent + _phase2Percent > 100) {
                _phase2Percent = 100 - _phase1Percent;
              }
            });
          }),
          _sectionDivider(),
          _buildPhaseRow(2, _phase2Percent, 0, 100 - _phase1Percent, (v) {
            setState(() => _phase2Percent = v);
          }),
          _sectionDivider(),
          _buildPhaseRow3(),
        ],
      ],
    );
  }

  Widget _buildPhaseRow(int phase, int percent, int min, int max, ValueChanged<int> onChanged) {
    final labels = ['', '一期', '二期', '三期'];
    return GestureDetector(
      onTap: () => _showPhasePicker(phase, percent, min, max, onChanged),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$phase',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              labels[phase],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseRow3() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '3',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey),
            ),
          ),
          const SizedBox(width: 10),
          const Text('三期（自动计算）', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            '$_phase3Percent%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  void _showPhasePicker(int phase, int current, int min, int max, ValueChanged<int> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    pressedOpacity: 0.5,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('取消', style: TextStyle(fontSize: 17)),
                  ),
                  Text('选择$phase期比例', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    pressedOpacity: 0.5,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('确定', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: CupertinoColors.systemGrey5),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: current - min),
                itemExtent: 32,
                onSelectedItemChanged: (v) => onChanged(min + v),
                children: List.generate(
                  max - min + 1,
                  (i) => Center(child: Text('${min + i}%', style: const TextStyle(fontSize: 20))),
                ),
              ),
            ),
            // Face recognition note
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.camera_viewfinder, size: 14, color: CupertinoColors.systemGrey3),
                  SizedBox(width: 4),
                  Text('需双方人脸识别确认',
                      style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3)),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildTermsSection() {
    return Column(
      children: [
        // Template selector
        GestureDetector(
          onTap: _showTemplateSheet,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(CupertinoIcons.doc_text, size: 18, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                const Text('选择范文', style: TextStyle(fontSize: 16, color: CupertinoColors.activeBlue)),
                const Spacer(),
                const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey3),
              ],
            ),
          ),
        ),
        _buildTermsDivider(),
        _buildTermsField(),
        _buildTermsDivider(),
        _buildBreachField(),
      ],
    );
  }

  void _showTemplateSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择担保范文'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _termsController.text = '卖方保证商品完好无损，按时交付。买方应在收到商品后24小时内验收确认。逾期未验收视为自动确认。';
            },
            child: const Text('货物买卖 - 商品交易担保'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _termsController.text = '服务方应按照约定标准完成服务交付。委托方应在服务完成后3个工作日内验收。验收不合格需书面说明理由。';
            },
            child: const Text('服务外包 - 服务交付担保'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _termsController.text = '借款方应于约定日期前全额归还。逾期按违约金比例每日计算。担保方承担连带保证责任。';
            },
            child: const Text('借款担保 - 资金借贷担保'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _termsController.clear();
            },
            child: const Text('自定义 - 空白模板'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildTermsDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 14),
      color: CupertinoColors.systemGrey5,
    );
  }

  Widget _buildTermsField() {
    return CupertinoTextField(
      controller: _termsController,
      placeholder: '请详细描述担保事项、交付标准、违约条件等',
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 16),
      style: const TextStyle(fontSize: 16),
      maxLines: 3,
      minLines: 3,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(),
    );
  }

  void _showDatePicker() {
    final now = DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    pressedOpacity: 0.5,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('取消', style: TextStyle(fontSize: 17)),
                  ),
                  const Text('选择交付时间', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    pressedOpacity: 0.5,
                    onPressed: () {
                      final selected = DateTime(_selectedYear, _selectedMonth, _selectedDay, _selectedHour);
                      if (selected.isBefore(now)) {
                        showCupertinoDialog(
                          context: ctx,
                          builder: (dctx) => CupertinoAlertDialog(
                            content: const Text('请选择明天及以后的日期和时间'),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.of(dctx).pop(),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      setState(() => _dateSelected = true);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('确定', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: CupertinoColors.systemGrey5),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: _selectedYear - now.year),
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => setState(() => _selectedYear = now.year + v),
                      children: List.generate(
                        10,
                        (i) => Center(child: Text('${now.year + i}年', style: const TextStyle(fontSize: 17))),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: _selectedMonth - 1),
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => setState(() => _selectedMonth = v + 1),
                      children: List.generate(
                        12,
                        (i) => Center(child: Text('${i + 1}月', style: const TextStyle(fontSize: 17))),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: _selectedDay - 1),
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => setState(() => _selectedDay = v + 1),
                      children: List.generate(
                        31,
                        (i) => Center(child: Text('${i + 1}日', style: const TextStyle(fontSize: 17))),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: _selectedHour),
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => setState(() => _selectedHour = v),
                      children: List.generate(
                        24,
                        (i) => Center(child: Text('$i时', style: const TextStyle(fontSize: 17))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreachField() {
    return CupertinoTextField(
      controller: _breachController,
      placeholder: '请描述违约处理方式，如解除合同、赔偿损失等',
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 16),
      style: const TextStyle(fontSize: 16),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 14, right: 4),
        child: Icon(CupertinoIcons.exclamationmark_triangle, size: 18, color: CupertinoColors.systemGrey2),
      ),
    );
  }
}
