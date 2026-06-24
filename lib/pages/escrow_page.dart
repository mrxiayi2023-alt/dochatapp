import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'escrow_create_page.dart';
import '../services/notification_service.dart';

class _EscrowOrder {
  final String id;
  final String contractNo;
  final String title;
  final double amount;
  final double breachRate;
  final int depositMode; // 0=单向上押, 1=双向上押
  final int depositPayer; // 0=发起方上押 1=接收方上押(仅单向上押时有效)
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
  // Evidence for arbitration
  final List<Map<String, dynamic>> evidence = [];
  String? evidenceNote;

  _EscrowOrder({
    required this.id,
    required this.contractNo,
    required this.title,
    required this.amount,
    required this.breachRate,
    required this.depositMode,
    required this.depositPayer,
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
          const Text('  -  ', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
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
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('电波担保'),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (_orders.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.shield_lefthalf_fill, size: 48, color: CupertinoColors.systemGrey3),
                        SizedBox(height: 12),
                        Text('暂无担保交易', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                        SizedBox(height: 4),
                        Text('点击右下角 创建担保交易', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
                      ],
                    ),
                  ),
                )
              else ...[
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
                          Text('待处理${_orders.where((o) => o.status != "completed" && o.status != "cancelled").length} 笔', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
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
      depositPayer: result['deposit_payer'] as int? ?? 0,
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
    // 双向上押：发起方创建时已付押金
    if (result['initiator_paid'] == true) {
      order.initiatorDepositPaid = true;
    }
    setState(() => _orders.insert(0, order));
  }

  Widget _buildOrderCard(_EscrowOrder order) {
    final statusText = _statusLabel(order.status);
    final statusColor = _statusColor(order.status);
    final feeLabel = ['发起方', '接收方', '平摊'][order.feePayer];
    final depositLabel = order.depositMode == 0
        ? (order.depositPayer == 0 ? '单向上押（发起方）' : '单向上押（接收方）')
        : '双向上押';
    final depositNote = order.depositMode == 0
        ? (order.depositPayer == 0 ? '发起方付清即可生效' : '接收方付清即可生效')
        : '双方付清后方可生效';
    final showInitiatorDeposit = order.depositMode == 1 || order.depositPayer == 0;
    final showCounterpartyDeposit = order.depositMode == 1 || order.depositPayer == 1;
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
                    if (showInitiatorDeposit)
                      _buildDepositPaidRow('发起方', order.initiatorDepositPaid),
                    if (showInitiatorDeposit && showCounterpartyDeposit)
                      const SizedBox(height: 2),
                    if (showCounterpartyDeposit)
                      _buildDepositPaidRow('接收方', order.counterpartyDepositPaid),
                    const SizedBox(height: 2),
                    Text(depositNote, style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey3)),
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
                        onPressed: () => _showConfirmDetailDialog(order),
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
                        onPressed: () => _advanceStatus(order, 'reviewing', '已提交验证'),
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
                    // 仲裁按钮 — 仅订单生效后 (active/reviewing) 双方可申请仲裁
                    if (order.status == 'active' || order.status == 'reviewing')
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
        Text(paid ? '已付🟢' : '未付🔴',
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
          mark = ' ';
        } else if (pending) {
          mark = ' ';
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
      case 'reviewing': return '待验证';
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

  bool _needsDeposit(_EscrowOrder order) {
    if (order.depositMode == 1) {
      // 双向上押：任一方未付清
      return !order.initiatorDepositPaid || !order.counterpartyDepositPaid;
    }
    // 单向上押：看付钱的那方是否未付
    if (order.depositPayer == 0) {
      return !order.initiatorDepositPaid;
    }
    return !order.counterpartyDepositPaid;
  }

  void _showOrderDetail(_EscrowOrder order) {
    // 查看担保单详情 — 清除担保角标
    NotificationService.clearBadge('escrow');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(order.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: _buildFullDetailContent(order),
        actions: [
          if (order.status == 'waiting_confirmation') ...[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showConfirmDetailDialog(order);
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
                _advanceStatus(order, 'reviewing', '已提交验证');
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
          // Simulate deposit payment — only show if relevant party hasn't paid
          if (_needsDeposit(order))
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _simulatePayDeposit(order);
              },
              child: const Text('模拟押金付清'),
            ),
          // Arbitration button — only active/reviewing orders (双方可申请仲裁
          if (order.status == 'active' || order.status == 'reviewing')
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
              Text('将随机邀请9位信誉良好的用户组成陪审团进行裁定。',
                  style: TextStyle(fontSize: 14)),
              SizedBox(height: 12),
              Text('陪审团规则：',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
              SizedBox(height: 6),
              _RuleItem('随机邀请9位信誉分≥85的用户'),
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
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 16, color: CupertinoColors.systemOrange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('⚠️ 资金已冻结，待争议解决后按结果分配',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text('陪审团已组建，请提交证据材料。',
                  style: TextStyle(fontSize: 14)),
              SizedBox(height: 4),
              Text('预计24小时内做出裁定。',
                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _showEvidenceDialog(order);
            },
            child: const Text('提交证据'),
          ),
        ],
      ),
    );
  }

  void _showEvidenceDialog(_EscrowOrder order) {
    final noteController = TextEditingController();
    if (order.evidenceNote != null) {
      noteController.text = order.evidenceNote!;
    }
    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: const Text('提交证据材料'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Evidence type selector
                  GestureDetector(
                    onTap: () => _showEvidenceTypeSheet(order, setDialogState),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.add_circled, size: 16, color: CupertinoColors.activeBlue),
                          SizedBox(width: 6),
                          Text('添加证据材料',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
                        ],
                      ),
                    ),
                  ),
                  // Submitted evidence list
                  if (order.evidence.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('已提交证据：',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 4),
                    ...order.evidence.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final typeStr = item['type'] as String;
                      final timeStr = item['time'] as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(_evidenceIcon(typeStr), style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(typeStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(timeStr, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.all(4),
                              minimumSize: Size.zero,
                              pressedOpacity: 0.5,
                              onPressed: () {
                                setDialogState(() => order.evidence.removeAt(idx));
                              },
                              child: const Icon(CupertinoIcons.delete, size: 16, color: CupertinoColors.destructiveRed),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 10),
                  // Supplementary note
                  CupertinoTextField(
                    controller: noteController,
                    placeholder: '请补充说明争议情况..',
                    placeholderStyle: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    minLines: 2,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (v) => order.evidenceNote = v,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('稍后提交'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (order.evidence.isEmpty) {
                  _showSimpleToast('请至少提交一项证据材料');
                  return;
                }
                _showSimpleToast('证据已提交，等待陪审团裁定');
                // 模拟陪审团裁定时长，5秒后自动执行裁定
                Timer(const Duration(seconds: 5), () {
                  if (mounted) {
                    _simulateVerdict(order);
                  }
                });
              },
              child: const Text('提交证据'),
            ),
          ],
        ),
      ),
    );
  }

  String _evidenceIcon(String type) {
    switch (type) {
      case '聊天记录': return '💬';
      case '图片': return '📷';
      case '视频': return '🎬';
      case '文件': return '📄';
      default: return '📎';
    }
  }

  void _showEvidenceTypeSheet(_EscrowOrder order, void Function(VoidCallback) setDialogState) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择证据类型'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setDialogState(() {
                order.evidence.add({'type': '聊天记录', 'time': timeStr});
              });
              _showSimpleToast('已自动截取双方聊天记录作为证据');
            },
            child: const Text('💬 聊天记录'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setDialogState(() {
                order.evidence.add({'type': '图片', 'time': timeStr});
              });
              _showSimpleToast('请上传相关图片证据');
            },
            child: const Text('📷 图片'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setDialogState(() {
                order.evidence.add({'type': '视频', 'time': timeStr});
              });
              _showSimpleToast('视频证据上传功能即将上线');
            },
            child: const Text('🎬 视频'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setDialogState(() {
                order.evidence.add({'type': '文件', 'time': timeStr});
              });
              _showSimpleToast('文件证据上传功能即将上线');
            },
            child: const Text('📄 文件'),
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

  void _simulateVerdict(_EscrowOrder order) {
    // Simulate a random verdict
    final buyerWins = DateTime.now().millisecond % 2 == 0;
    final verdict = buyerWins
        ? '陪审团裁定：支持发起方\n资金全额退还给发起方'
        : '陪审团裁定：支持接收方\n资金释放给接收方';
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('裁定结果'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(verdict, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                height: 0.5,
                color: CupertinoColors.systemGrey5,
              ),
              const SizedBox(height: 8),
              const Text(
                '本裁定为平台调解结果，不影响当事人依法向人民法院提起诉讼的权利。',
                style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                order.arbitrationVerdict = verdict;
              });
              _showSimpleToast('仲裁完成，已按裁定结果执行');
            },
            child: const Text('确认执行'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                order.arbitrationVerdict = verdict;
              });
              _showAppealNotice();
            },
            child: const Text('不服裁定'),
          ),
        ],
      ),
    );
  }

  void _showAppealNotice() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('不服裁定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 16, color: CupertinoColors.systemOrange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('⚠️ 资金已冻结，待争议解决后按结果分配',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('如对裁定结果不服，可自行向人民法院提起诉讼。',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              const Text('诉讼期间资金继续冻结，待法院判决后按判决执行。平台将保留所有证据材料，配合司法机关调取。',
                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 10),
              Container(
                height: 0.5,
                color: CupertinoColors.systemGrey5,
              ),
              const SizedBox(height: 8),
              const Text(
                '本裁定为平台调解结果，不影响当事人依法向人民法院提起诉讼的权利。',
                style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('我知道了'),
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
  // Counterparty confirmation flow (detail dialog first)
  // -------------------------------------------------------------------------

  void _showConfirmDetailDialog(_EscrowOrder order) {
    final depositLabel = order.depositMode == 0
        ? (order.depositPayer == 0 ? '单向上押（发起方）' : '单向上押（接收方）')
        : '双向上押';
    final depositNote = order.depositMode == 0
        ? (order.depositPayer == 0 ? '发起方付清即可生效' : '接收方付清即可生效')
        : '双方付清后方可生效';
    final needsPayment = order.depositMode == 1 || order.depositPayer == 1;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(order.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('合同编号', order.contractNo),
            const SizedBox(height: 4),
            _detailRow('对方', order.counterpartyName),
            const SizedBox(height: 4),
            _detailRow('金额', '¥${order.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _detailRow('押金方式', depositLabel + depositNote),
            const SizedBox(height: 4),
            _detailRow('交付时间', order.deliveryTime.isNotEmpty ? order.deliveryTime : '未约定'),
            const SizedBox(height: 4),
            _detailRow('违约金', '${(order.breachRate * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 10),
            const Text('请仔细核对以上信息，确认接受本担保单。',
                style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _counterpartyReject(order);
            },
            child: const Text('拒绝'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showFullDetailDialog(order, needsPayment);
            },
            child: const Text('查看详情'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (needsPayment) {
                _showPaymentChannelSheet(order);
              } else {
                _counterpartyConfirm(order);
              }
            },
            child: const Text('接受'),
          ),
        ],
      ),
    );
  }

  void _showFullDetailDialog(_EscrowOrder order, bool needsPayment) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(order.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: _buildFullDetailContent(order),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('返回'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _counterpartyReject(order);
            },
            child: const Text('拒绝'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (needsPayment) {
                _showPaymentChannelSheet(order);
              } else {
                _counterpartyConfirm(order);
              }
            },
            child: const Text('接受'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDetailContent(_EscrowOrder order) {
    final isCustody = order.status != 'completed' && order.status != 'cancelled';
    final depositLabel = order.depositMode == 0
        ? (order.depositPayer == 0 ? '单向上押（发起方）' : '单向上押（接收方）')
        : '双向上押';
    final depositNote = order.depositMode == 0
        ? (order.depositPayer == 0 ? '发起方付清即可生效' : '接收方付清即可生效')
        : '双方付清后方可生效';
    final showInitiatorDeposit = order.depositMode == 1 || order.depositPayer == 0;
    final showCounterpartyDeposit = order.depositMode == 1 || order.depositPayer == 1;
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('合同编号', order.contractNo),
            const SizedBox(height: 4),
            _detailRow('担保事项', order.title),
            const SizedBox(height: 4),
            _detailRow('对方', order.counterpartyName),
            const SizedBox(height: 4),
            _detailRow('手机', order.counterpartyPhone),
            const SizedBox(height: 4),
            _detailRow('金额', '¥${order.amount.toStringAsFixed(2)} (${isCustody ? "托管中" : "已释放"})'),
            const SizedBox(height: 4),
            _detailRow('违约金', '${(order.breachRate * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            _detailRow('押金方式', depositLabel),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showInitiatorDeposit)
                    Text('发起方：${order.initiatorDepositPaid ? "已付🟢" : "未付🔴"}',
                        style: TextStyle(fontSize: 12, color: order.initiatorDepositPaid ? CupertinoColors.systemGreen : CupertinoColors.systemGrey)),
                  if (showCounterpartyDeposit)
                    Text('接收方：${order.counterpartyDepositPaid ? "已付🟢" : "未付🔴"}',
                        style: TextStyle(fontSize: 12, color: order.counterpartyDepositPaid ? CupertinoColors.systemGreen : CupertinoColors.systemGrey)),
                  Text(depositNote, style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey3)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _detailRow('状态', _statusLabel(order.status)),
            const SizedBox(height: 4),
            _detailRow('交付时间', order.deliveryTime.isNotEmpty ? order.deliveryTime : '未约定'),
            const SizedBox(height: 4),
            _detailRow('服务费', ['发起方', '接收方', '平摊'][order.feePayer]),
            const SizedBox(height: 4),
            _detailRow('创建时间', order.createdAt.substring(0, 10)),
            if (order.installment) ...[
              const SizedBox(height: 10),
              Container(height: 0.5, color: CupertinoColors.systemGrey5),
              const SizedBox(height: 8),
              const Text('分阶段付款', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 4),
              for (final p in [1, 2, 3]) ...[
                const SizedBox(height: 2),
                Text(
                  '${_phaseLabel(p)}: ${p == 1 ? order.phase1Percent : p == 2 ? order.phase2Percent : order.phase3Percent}%'
                  '${order.completedPhases.contains(p) ? " ✓已完成" : order.pendingPhase == p ? " ⏳待确认" : ""}',
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
            if (order.terms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(height: 0.5, color: CupertinoColors.systemGrey5),
              const SizedBox(height: 8),
              const Text('担保条款', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 4),
              Text(order.terms, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
            if (order.breach.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('违约处理', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 4),
              Text(order.breach, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
            if (order.arbitrationVerdict != null) ...[
              const SizedBox(height: 10),
              Container(height: 0.5, color: CupertinoColors.systemGrey5),
              const SizedBox(height: 8),
              const Text('仲裁结果', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 4),
              Text(order.arbitrationVerdict!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.destructiveRed)),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentChannelSheet(_EscrowOrder order) {
    final payerLabel = order.depositMode == 0
        ? (order.depositPayer == 1 ? '接收方' : '发起方')
        : '双方';
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('$payerLabel支付押金'),
        message: const Text('请选择押金支付方式，支付后订单生效'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showPaymentSimulation(order, '支付押金');
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
              _showPaymentSimulation(order, '微信支付');
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

  void _showPaymentSimulation(_EscrowOrder order, String method) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('$method支付'),
        content: const Text('支付功能即将上线，模拟支付成功。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _counterpartyConfirm(order);
            },
            child: const Text('确认支付'),
          ),
        ],
      ),
    );
  }

  void _counterpartyConfirm(_EscrowOrder order) {
    setState(() {
      order.status = 'active';
      // 单向上押+发起方上押：发起方付清即可
      // 单向上押+接收方上押：接收方支付押金
      // 双向上押：发起方创建时已付，接收方确认时付清
      if (order.depositMode == 0 && order.depositPayer == 0) {
        order.initiatorDepositPaid = true;
        order.counterpartyDepositPaid = false;
      } else if (order.depositMode == 0 && order.depositPayer == 1) {
        order.initiatorDepositPaid = false;
        order.counterpartyDepositPaid = true;
      } else {
        // 双向上押：发起方已在创建时付清，此处接收方付款
        order.counterpartyDepositPaid = true;
      }
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
      if (order.depositMode == 0 && order.depositPayer == 0) {
        order.initiatorDepositPaid = true;
      } else if (order.depositMode == 0 && order.depositPayer == 1) {
        order.counterpartyDepositPaid = true;
      } else {
        order.initiatorDepositPaid = true;
        order.counterpartyDepositPaid = true;
      }
    });
    final label = order.depositMode == 0
        ? (order.depositPayer == 0 ? '发起方押金已付清' : '接收方押金已付清')
        : '双方押金已付清';
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
            child: Text('${_phaseLabel(phase)}: ${pct ?? 0}%'),
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
    _showSimpleToast('已发送${_phaseLabel(phase)}收款申请（$percent%），等待发起方确认');
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
              _showSimpleToast('人脸识别通过${_phaseLabel(phase)}款项已释放');
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
        content: const Text('拒绝后接收方可申请仲裁。\n\n确认拒绝。'),
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
              _showSimpleToast('已拒绝{_phaseLabel(phase)}付款，接收方可申请仲裁');
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
