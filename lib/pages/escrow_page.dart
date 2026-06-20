import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'escrow_create_page.dart';

class _EscrowOrder {
  final String id;
  final String contractNo;
  final String title;
  final double amount;
  final double breachRate;
  final int depositMode; // 0=单向押金, 1=双向押金
  final String counterpartyName;
  final String counterpartyPhone;
  String status;
  final bool installment;
  final int? phase1Percent;
  final int? phase2Percent;
  final int? phase3Percent;
  final int feePayer;
  final String createdAt;
  final String terms;
  final String deliveryTime;
  final String breach;
  String? arbitrationVerdict;
  // Deposit & phase payment state
  bool initiatorDepositPaid = false;
  bool counterpartyDepositPaid = false;
  int? pendingPhase; // phase number (1/2/3) awaiting initiator confirmation
  final Set<int> completedPhases = {};
  bool counterpartyRejected = false;

  _EscrowOrder({
    required this.id,
    required this.contractNo,
    required this.title,
    required this.amount,
    required this.breachRate,
    required this.depositMode,
    required this.counterpartyName,
    required this.counterpartyPhone,
    required this.status,
    required this.installment,
    this.phase1Percent,
    this.phase2Percent,
    this.phase3Percent,
    required this.feePayer,
    required this.createdAt,
    required this.terms,
    required this.deliveryTime,
    required this.breach,
  });
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  •  ', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey))),
        ],
      ),
    );
  }
}

class EscrowPage extends StatefulWidget {
  const EscrowPage({super.key});
  @override
  State<EscrowPage> createState() => _EscrowPageState();
}

class _EscrowPageState extends State<EscrowPage> {
  static final List<_EscrowOrder> _orders = [];
  static int _contractCounter = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: Stack(
        children: [
          if (_orders.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.shield_lefthalf_fill, size: 48, color: CupertinoColors.systemGrey3),
                  const SizedBox(height: 12),
                  const Text('暂无担保单', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 4),
                  const Text('点击右下角 + 创建担保交易', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
                ],
              ),
            )
          else
            CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(largeTitle: const Text('电波担保')),
                // Custody summary bar
                if (_isCustody)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.shield_lefthalf_fill, size: 18, color: CupertinoColors.activeBlue),
                          const SizedBox(width: 8),
                          const Text('资金托管中', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
                          const Spacer(),
                          Text('共 ${_orders.where((o) => o.status != "completed" && o.status != "cancelled").length} 笔',
                              style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                        ],
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildOrderCard(_orders[index]),
                    childCount: _orders.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          Positioned(
            right: 20, bottom: 20,
            child: CupertinoButton(
              onPressed: _openCreatePage,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: EdgeInsets.zero,
              child: const SizedBox(width: 56, height: 56, child: Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 28)),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreatePage() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(fullscreenDialog: true, builder: (_) => const EscrowCreatePage()),
    );
    if (result == null || !mounted) return;
    _contractCounter++;
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final contractNo = 'DB-$dateStr-${_contractCounter.toString().padLeft(3, '0')}';
    final order = _EscrowOrder(
      id: 'ESC${now.millisecondsSinceEpoch}',
      contractNo: contractNo,
      title: result['title'] as String? ?? '',
      amount: (result['amount'] as num?)?.toDouble() ?? 0,
      breachRate: (result['breach_rate'] as num?)?.toDouble() ?? 0.05,
      depositMode: result['deposit_mode'] as int? ?? 0,
      counterpartyName: result['counterparty_name'] as String? ?? '',
      counterpartyPhone: result['counterparty_phone'] as String? ?? '',
      status: 'waiting_confirmation',
      installment: result['installment'] as bool? ?? false,
      phase1Percent: result['phase1_percent'] as int?,
      phase2Percent: result['phase2_percent'] as int?,
      phase3Percent: result['phase3_percent'] as int?,
      feePayer: result['fee_payer'] as int? ?? 0,
      createdAt: now.toIso8601String(),
      terms: result['terms'] as String? ?? '',
      deliveryTime: result['delivery_time'] as String? ?? '',
      breach: result['breach'] as String? ?? '',
    );
    setState(() => _orders.insert(0, order));
  }

  Widget _buildOrderCard(_EscrowOrder order) {
    final statusText = _statusLabel(order.status);
    final statusColor = _statusColor(order.status);
    final feeLabel = ['发起方', '接收方', '平摊'][order.feePayer];
    final depositLabel = ['单向押金', '双向押金'][order.depositMode];
    final isCustody = order.status != 'completed' && order.status != 'cancelled';

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(order.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(order.contractNo, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3)),
              const SizedBox(height: 10),
              _buildInfoRow(CupertinoIcons.person_2, '对方', order.counterpartyName),
              const SizedBox(height: 6),
              _buildInfoRow(CupertinoIcons.money_yen_circle, '担保金额',
                  '¥${order.amount.toStringAsFixed(2)} ${isCustody ? "(托管中)" : "(已释放)"}'),
              const SizedBox(height: 6),
              _buildInfoRow(CupertinoIcons.shield, '押金方式', depositLabel),
              // Deposit payment status
              Padding(
                padding: const EdgeInsets.only(left: 21, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDepositPaidRow('发起方', order.initiatorDepositPaid),
                    if (order.depositMode == 1) ...[
                      const SizedBox(height: 2),
                      _buildDepositPaidRow('接收方', order.counterpartyDepositPaid),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _buildInfoRow(CupertinoIcons.phone, '对方手机', order.counterpartyPhone),
              const SizedBox(height: 6),
              _buildInfoRow(CupertinoIcons.doc_text, '服务费承担', feeLabel),
              if (order.installment) ...[
                const SizedBox(height: 6),
                _buildInfoRow(CupertinoIcons.clock, '付款方式', '分阶段付款'),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 21),
                  child: _buildPhaseProgress(order),
                ),
              ],
              // Pending phase payment - initiator sees confirm/reject
              if (order.pendingPhase != null && order.status == 'active') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.systemOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('接收方申请${_phaseLabel(order.pendingPhase!)}收款',
                            style: const TextStyle(fontSize: 12, color: CupertinoColors.systemOrange)),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(10),
                        color: CupertinoColors.systemGreen,
                        pressedOpacity: 0.7,
                        onPressed: () => _confirmPhasePayment(order),
                        child: const Text('确认付款', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                      const SizedBox(width: 6),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(10),
                        color: CupertinoColors.destructiveRed,
                        pressedOpacity: 0.7,
                        onPressed: () => _rejectPhasePayment(order),
                        child: const Text('拒绝', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                    ],
                  ),
                ),
              ],
              // Quick action buttons
              if (order.status == 'waiting_confirmation' || order.status == 'active' || order.status == 'reviewing' || order.status == 'disputed' || order.status == 'rejected') ...[
                const SizedBox(height: 12),
                Container(
                  height: 0.5,
                  color: CupertinoColors.systemGrey5,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 接收方：确认/拒绝担保 (waiting_confirmation)
                    if (order.status == 'waiting_confirmation') ...[
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: CupertinoColors.systemGreen,
                        pressedOpacity: 0.7,
                        onPressed: () => _counterpartyConfirm(order),
                        child: const Text('接收方确认', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: CupertinoColors.destructiveRed.withValues(alpha: 0.8),
                        pressedOpacity: 0.7,
                        onPressed: () => _counterpartyReject(order),
                        child: const Text('接收方拒绝', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                    ],
                    // 发起方：确认履约 (active)
                    if (order.status == 'active')
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: CupertinoColors.activeBlue,
                        pressedOpacity: 0.7,
                        onPressed: () => _advanceStatus(order, 'reviewing', '已提交验收'),
                        child: const Text('确认履约', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                    // 接收方：申请阶段收款 (active, installment)
                    if (order.status == 'active' && order.installment && order.completedPhases.length < 3)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: CupertinoColors.systemTeal,
                        pressedOpacity: 0.7,
                        onPressed: () => _showRequestPhaseSheet(order),
                        child: const Text('申请阶段收款', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                    // 发起方：确认验收 (reviewing)
                    if (order.status == 'reviewing')
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: CupertinoColors.systemPurple,
                        pressedOpacity: 0.7,
                        onPressed: () => _advanceStatus(order, 'completed', '担保单已完成，资金已释放'),
                        child: const Text('确认验收', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                    // 仲裁按钮
                    // 触发条件：接收方拒绝确认 | 接收方超时未确认 | 发起方拒绝阶段付款
                    if (order.status == 'rejected' || order.status == 'active' || order.status == 'reviewing')
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: CupertinoColors.destructiveRed,
                        pressedOpacity: 0.7,
                        onPressed: () => _showArbitrationDialog(order),
                        child: const Text('申请仲裁', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositPaidRow(String role, bool paid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(role, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey2)),
        const SizedBox(width: 4),
        Text(paid ? '已付🟢' : '未付⚫',
            style: TextStyle(fontSize: 11, color: paid ? CupertinoColors.systemGreen : CupertinoColors.systemGrey2)),
      ],
    );
  }

  Widget _buildPhaseProgress(_EscrowOrder order) {
    final phases = [
      (1, order.phase1Percent ?? 0),
      (2, order.phase2Percent ?? 0),
      (3, order.phase3Percent ?? 0),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: phases.map((p) {
        final (num, pct) = p;
        final done = order.completedPhases.contains(num);
        final pending = order.pendingPhase == num;
        String mark = '';
        if (done) {
          mark = ' ✓';
        } else if (pending) {
          mark = ' ⏳';
        }
        return Text(
          '${_phaseLabel(num)}$pct%$mark',
          style: TextStyle(
            fontSize: 11,
            color: done
                ? CupertinoColors.systemGreen
                : pending
                    ? CupertinoColors.systemOrange
                    : CupertinoColors.systemGrey2,
            fontWeight: done ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }

  String _phaseLabel(int phase) {
    return ['', '一期', '二期', '三期'][phase];
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 15, color: CupertinoColors.systemGrey2),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
    ]);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'waiting_confirmation': return '待对方确认';
      case 'active': return '履约中';
      case 'reviewing': return '待验收';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      case 'disputed': return '争议中';
      case 'rejected': return '已拒绝';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'waiting_confirmation': return CupertinoColors.systemOrange;
      case 'active': return CupertinoColors.activeBlue;
      case 'reviewing': return CupertinoColors.systemPurple;
      case 'completed': return CupertinoColors.systemGreen;
      case 'cancelled': return CupertinoColors.systemGrey;
      case 'disputed': return CupertinoColors.destructiveRed;
      case 'rejected': return CupertinoColors.destructiveRed;
      default: return CupertinoColors.systemGrey;
    }
  }

  bool get _isCustody =>
      _orders.any((o) => o.status == 'waiting_confirmation' || o.status == 'active' || o.status == 'reviewing' || o.status == 'disputed');

  void _showOrderDetail(_EscrowOrder order) {
    final isCustody = order.status != 'completed' && order.status != 'cancelled';
    final depositLabel = ['单向押金', '双向押金'][order.depositMode];
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(order.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('合同编号', order.contractNo),
                const SizedBox(height: 4),
                _detailRow('对方', order.counterpartyName),
                const SizedBox(height: 4),
                _detailRow('手机', order.counterpartyPhone),
                const SizedBox(height: 4),
                _detailRow('金额', '¥${order.amount.toStringAsFixed(2)} (${isCustody ? "托管中" : "已释放"})'),
                const SizedBox(height: 4),
                _detailRow('押金方式', depositLabel),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('发起方：${order.initiatorDepositPaid ? "已付🟢" : "未付⚫"}',
                          style: TextStyle(fontSize: 12, color: order.initiatorDepositPaid ? CupertinoColors.systemGreen : CupertinoColors.systemGrey)),
                      if (order.depositMode == 1)
                        Text('接收方：${order.counterpartyDepositPaid ? "已付🟢" : "未付⚫"}',
                            style: TextStyle(fontSize: 12, color: order.counterpartyDepositPaid ? CupertinoColors.systemGreen : CupertinoColors.systemGrey)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _detailRow('状态', _statusLabel(order.status)),
                const SizedBox(height: 4),
                _detailRow('交付时间', order.deliveryTime.isNotEmpty ? order.deliveryTime : '未约定'),
                const SizedBox(height: 4),
                _detailRow('创建时间', order.createdAt.substring(0, 10)),
                // Installment details
                if (order.installment) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 0.5,
                    color: CupertinoColors.systemGrey5,
                  ),
                  const SizedBox(height: 8),
                  const Text('分阶段付款', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 4),
                  for (final p in [1, 2, 3]) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_phaseLabel(p)}：${p == 1 ? order.phase1Percent : p == 2 ? order.phase2Percent : order.phase3Percent}%'
                      '${order.completedPhases.contains(p) ? " ✓已付" : order.pendingPhase == p ? " ⏳待确认" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        color: order.completedPhases.contains(p) ? CupertinoColors.systemGreen : CupertinoColors.black,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  const Text('每期均需双方人脸识别确认',
                      style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3)),
                ],
                // Contract terms
                if (order.terms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 0.5,
                    color: CupertinoColors.systemGrey5,
                  ),
                  const SizedBox(height: 8),
                  const Text('担保约定', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 4),
                  Text(order.terms, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
                if (order.breach.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('违约处理', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 4),
                  Text(order.breach, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
                // Arbitration verdict
                if (order.arbitrationVerdict != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 0.5,
                    color: CupertinoColors.systemGrey5,
                  ),
                  const SizedBox(height: 8),
                  const Text('仲裁结果', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 4),
                  Text(order.arbitrationVerdict!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.destructiveRed)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (order.status == 'waiting_confirmation') ...[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _counterpartyConfirm(order);
              },
              child: const Text('模拟接收方确认'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _counterpartyReject(order);
              },
              child: const Text('模拟接收方拒绝'),
            ),
          ],
          if (order.status == 'active')
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _advanceStatus(order, 'reviewing', '已提交验收');
              },
              child: const Text('确认履约完成'),
            ),
          if (order.status == 'reviewing')
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _advanceStatus(order, 'completed', '担保单已完成，资金已释放');
              },
              child: const Text('确认验收'),
            ),
          // Simulate deposit payment
          if (!order.initiatorDepositPaid || (order.depositMode == 1 && !order.counterpartyDepositPaid))
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _simulatePayDeposit(order);
              },
              child: const Text('模拟押金付清'),
            ),
          // Arbitration button
          if (order.status == 'active' || order.status == 'reviewing' || order.status == 'rejected')
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _showArbitrationDialog(order);
              },
              child: const Text('申请仲裁'),
            ),
          if (order.status == 'disputed' && order.arbitrationVerdict == null)
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _simulateVerdict(order);
              },
              child: const Text('模拟裁定结果'),
            ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  void _showArbitrationDialog(_EscrowOrder order) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('申请仲裁'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('将随机邀请19位信誉良好的用户组成陪审团进行裁定。',
                  style: TextStyle(fontSize: 14)),
              SizedBox(height: 12),
              Text('陪审团规则：',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
              SizedBox(height: 6),
              _RuleItem('随机邀请19位信誉分≥85的用户'),
              _RuleItem('双方提交凭证后，陪审团投票'),
              _RuleItem('先到10票的一方获胜'),
              _RuleItem('裁定结果为最终结果，立即执行资金分配'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _startArbitration(order);
            },
            child: const Text('确认申请'),
          ),
        ],
      ),
    );
  }

  void _startArbitration(_EscrowOrder order) {
    setState(() => order.status = 'disputed');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('仲裁已受理'),
        content: const Text('陪审团已组建，预计24小时内做出裁定。\n\n请耐心等待陪审团投票结果。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              // 模拟陪审团裁定时长，5秒后自动执行裁定
              Timer(const Duration(seconds: 5), () {
                if (mounted) {
                  _simulateVerdict(order);
                }
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _simulateVerdict(_EscrowOrder order) {
    // Simulate a random verdict
    final buyerWins = DateTime.now().millisecond % 2 == 0;
    final verdict = buyerWins ? '陪审团裁定：支持买家\n资金全额退还给买家' : '陪审团裁定：支持卖家\n资金释放给卖家';
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('裁定结果'),
        content: Text(verdict, style: const TextStyle(fontSize: 14)),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                order.arbitrationVerdict = verdict;
                order.status = 'completed';
              });
              _showSimpleToast('仲裁完成，已按裁定结果执行');
            },
            child: const Text('确认执行'),
          ),
        ],
      ),
    );
  }

  void _showSimpleToast(String message) {
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

  // -------------------------------------------------------------------------
  // Counterparty actions
  // -------------------------------------------------------------------------

  void _counterpartyConfirm(_EscrowOrder order) {
    setState(() {
      order.status = 'active';
      order.initiatorDepositPaid = true;
      order.counterpartyDepositPaid = true;
    });
    _showSimpleToast('接收方已确认担保单，押金已付清，订单生效');
  }

  void _counterpartyReject(_EscrowOrder order) {
    setState(() {
      order.status = 'rejected';
      order.counterpartyRejected = true;
    });
    _showSimpleToast('接收方已拒绝担保单，发起方可申请仲裁');
  }

  // -------------------------------------------------------------------------
  // Deposit simulation
  // -------------------------------------------------------------------------

  void _simulatePayDeposit(_EscrowOrder order) {
    setState(() {
      order.initiatorDepositPaid = true;
      if (order.depositMode == 1) {
        order.counterpartyDepositPaid = true;
      }
    });
    final label = order.depositMode == 0 ? '发起方押金已付清' : '双方押金已付清';
    _showSimpleToast(label);
  }

  // -------------------------------------------------------------------------
  // Phase payment flow
  // -------------------------------------------------------------------------

  void _showRequestPhaseSheet(_EscrowOrder order) {
    final available = <int>[];
    for (var i = 1; i <= 3; i++) {
      if (!order.completedPhases.contains(i) && order.pendingPhase != i) {
        available.add(i);
      }
    }
    if (available.isEmpty) {
      _showSimpleToast('所有阶段已完成或待确认');
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择收款阶段'),
        actions: available.map((phase) {
          final pct = phase == 1
              ? order.phase1Percent
              : phase == 2
                  ? order.phase2Percent
                  : order.phase3Percent;
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _requestPhasePayment(order, phase, pct ?? 0);
            },
            child: Text('${_phaseLabel(phase)}（${pct ?? 0}%）'),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _requestPhasePayment(_EscrowOrder order, int phase, int percent) {
    setState(() => order.pendingPhase = phase);
    _showSimpleToast('已发起${_phaseLabel(phase)}收款申请（$percent%），等待发起方确认');
  }

  void _confirmPhasePayment(_EscrowOrder order) {
    final phase = order.pendingPhase;
    if (phase == null) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('人脸识别验证'),
        content: const Text('将进行人脸识别验证，确认后款项将释放给接收方。\n\n请确保光线充足，面部正对摄像头。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                order.completedPhases.add(phase);
                order.pendingPhase = null;
              });
              _showSimpleToast('人脸识别通过，${_phaseLabel(phase)}款项已释放');
            },
            child: const Text('开始识别'),
          ),
        ],
      ),
    );
  }

  void _rejectPhasePayment(_EscrowOrder order) {
    final phase = order.pendingPhase;
    if (phase == null) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('拒绝阶段付款'),
        content: const Text('拒绝后接收方可申请仲裁。\n\n确认拒绝？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => order.pendingPhase = null);
              _showSimpleToast('已拒绝${_phaseLabel(phase)}付款，接收方可申请仲裁');
            },
            child: const Text('确认拒绝'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Status advancement
  // -------------------------------------------------------------------------

  void _advanceStatus(_EscrowOrder order, String newStatus, String message) {
    setState(() => order.status = newStatus);
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
}
