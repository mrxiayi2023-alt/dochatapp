import 'package:flutter/cupertino.dart';
import 'escrow_create_page.dart';

class _EscrowOrder {
  final String id;
  final String title;
  final double amount;
  final double depositRate;
  final String counterpartyPhone;
  final String status;
  final bool installment;
  final int feePayer;
  final String createdAt;

  const _EscrowOrder({
    required this.id,
    required this.title,
    required this.amount,
    required this.depositRate,
    required this.counterpartyPhone,
    required this.status,
    required this.installment,
    required this.feePayer,
    required this.createdAt,
  });
}

class EscrowPage extends StatefulWidget {
  const EscrowPage({super.key});
  @override
  State<EscrowPage> createState() => _EscrowPageState();
}

class _EscrowPageState extends State<EscrowPage> {
  static final List<_EscrowOrder> _orders = [];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: Stack(
        children: [
          if (_orders.isEmpty)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.shield_lefthalf_fill, size: 48, color: CupertinoColors.systemGrey3),
                  SizedBox(height: 12),
                  Text('暂无担保单', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                  SizedBox(height: 4),
                  Text('点击右下角 + 创建担保交易', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
                ],
              ),
            )
          else
            CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(largeTitle: const Text('电波担保')),
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
    final order = _EscrowOrder(
      id: 'ESC${DateTime.now().millisecondsSinceEpoch}',
      title: result['title'] as String? ?? '',
      amount: (result['amount'] as num?)?.toDouble() ?? 0,
      depositRate: (result['deposit_rate'] as num?)?.toDouble() ?? 0.05,
      counterpartyPhone: result['counterparty_phone'] as String? ?? '',
      status: 'pending',
      installment: result['installment'] as bool? ?? false,
      feePayer: result['fee_payer'] as int? ?? 0,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _orders.insert(0, order));
  }

  Widget _buildOrderCard(_EscrowOrder order) {
    final statusText = _statusLabel(order.status);
    final statusColor = _statusColor(order.status);
    final feeLabel = ['发起方', '接收方', '平摊'][order.feePayer];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: CupertinoColors.systemGrey4.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(order.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor))),
            ]),
            const SizedBox(height: 10),
            _buildInfoRow(CupertinoIcons.money_yen_circle, '担保金额', '¥${order.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _buildInfoRow(CupertinoIcons.percent, '押金比例', '${(order.depositRate * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 6),
            _buildInfoRow(CupertinoIcons.phone, '对方手机号', order.counterpartyPhone),
            const SizedBox(height: 6),
            _buildInfoRow(CupertinoIcons.person_2, '服务费承担', feeLabel),
            if (order.installment) ...[const SizedBox(height: 6), _buildInfoRow(CupertinoIcons.clock, '付款方式', '分阶段付款')],
          ],
        ),
      ),
    );
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
      case 'pending': return '待确认';
      case 'active': return '进行中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return CupertinoColors.systemOrange;
      case 'active': return CupertinoColors.activeBlue;
      case 'completed': return CupertinoColors.systemGreen;
      case 'cancelled': return CupertinoColors.systemGrey;
      default: return CupertinoColors.systemGrey;
    }
  }
}
