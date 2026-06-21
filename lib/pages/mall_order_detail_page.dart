import 'package:flutter/cupertino.dart';
import '../services/order_service.dart';
import 'mall_dispute_page.dart';

class MallOrderDetailPage extends StatefulWidget {
  final OrderInfo order;
  const MallOrderDetailPage({super.key, required this.order});
  @override
  State<MallOrderDetailPage> createState() => _MallOrderDetailPageState();
}

class _MallOrderDetailPageState extends State<MallOrderDetailPage> {
  late OrderInfo _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _refreshOrder() {
    final idx = OrderService.orders.indexWhere((o) => o.orderId == _order.orderId);
    if (idx != -1) {
      _order = OrderService.orders[idx];
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return CupertinoColors.systemOrange;
      case 'shipped': return CupertinoColors.activeBlue;
      case 'received': return CupertinoColors.systemGreen;
      case 'completed': return CupertinoColors.systemGrey;
      default: return CupertinoColors.systemGrey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'paid': return '待发货';
      case 'shipped': return '已发货';
      case 'received': return '已收货';
      case 'completed': return '已完成';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid': return CupertinoIcons.clock;
      case 'shipped': return CupertinoIcons.cube_box;
      case 'received': return CupertinoIcons.checkmark_alt_circle;
      case 'completed': return CupertinoIcons.checkmark_seal;
      default: return CupertinoIcons.question_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('订单详情'),
        trailing: GestureDetector(
          onTap: _showReportSheet,
          child: const Icon(CupertinoIcons.exclamationmark_bubble, size: 22, color: CupertinoColors.systemGrey),
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: OrderService.changeNotifier,
          builder: (context, _, _) {
            _refreshOrder();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: 12),
                  _buildProductSection(),
                  const SizedBox(height: 12),
                  _buildLogisticsTimeline(),
                  const SizedBox(height: 12),
                  _buildMapPlaceholder(),
                  const SizedBox(height: 12),
                  _buildSellerCard(),
                  const SizedBox(height: 12),
                  _buildAmountBreakdown(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final color = _statusColor(_order.status);
    final text = _statusText(_order.status);
    final icon = _statusIcon(_order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('订单号：', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              Expanded(child: Text(_order.orderId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 10),
              Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              const Spacer(),
              if (_order.status == 'completed')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('已完成', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.systemGreen)),
                ),
            ],
          ),
          if (_order.trackingNumber != null && _order.trackingNumber!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.cube_box, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 6),
                Text('快递单号：${_order.trackingNumber}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('商品信息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._order.items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: e.product.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(e.product.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('¥${e.product.price} x ${e.quantity}', style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                          Text('¥${(double.parse(e.product.price) * e.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLogisticsTimeline() {
    final logisticsSteps = [
      {'key': 'picked_up', 'label': '已揽收', 'icon': CupertinoIcons.archivebox, 'desc': '快递员已取件'},
      {'key': 'transporting', 'label': '运输中', 'icon': CupertinoIcons.arrow_right_arrow_left, 'desc': '包裹在途中'},
      {'key': 'delivering', 'label': '派送中', 'icon': CupertinoIcons.location, 'desc': '快递员正在派送'},
      {'key': 'signed', 'label': '已签收', 'icon': CupertinoIcons.checkmark_seal, 'desc': '收件人已签收'},
    ];
    final currentIdx = logisticsSteps.indexWhere((s) => s['key'] == _order.logistics);
    final displayIdx = currentIdx == -1 ? 0 : currentIdx;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('物流轨迹', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...List.generate(logisticsSteps.length, (i) {
            final isCompleted = i <= displayIdx;
            final isCurrent = i == displayIdx;
            final step = logisticsSteps[i];
            final dotColor = isCompleted
                ? (isCurrent ? CupertinoColors.activeBlue : CupertinoColors.systemGreen)
                : CupertinoColors.systemGrey5;
            final textColor = isCompleted
                ? (isCurrent ? CupertinoColors.activeBlue : CupertinoColors.darkBackgroundGray)
                : CupertinoColors.systemGrey3;

            return SizedBox(
              height: i < logisticsSteps.length - 1 ? 64 : 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: isCompleted
                            ? const Icon(CupertinoIcons.checkmark_alt, size: 13, color: CupertinoColors.white)
                            : Icon(step['icon'] as IconData, size: 12, color: CupertinoColors.systemGrey3),
                      ),
                      if (i < logisticsSteps.length - 1)
                        Container(
                          width: 2,
                          height: 32,
                          color: i < displayIdx ? CupertinoColors.systemGreen : CupertinoColors.systemGrey5,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 2),
                      Text(step['desc'] as String, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\u{1F4CD}', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('物流轨迹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.darkBackgroundGray)),
          const SizedBox(height: 4),
          const Text('预留高德SDK接口', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3)),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    final firstItem = _order.items.isNotEmpty ? _order.items.first : null;
    final seller = firstItem?.product.seller ?? '未知卖家';
    final reputation = firstItem?.product.reputation ?? 0;
    final repColor = _reputationColor(reputation);
    final tier = _reputationTier(reputation);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(seller.substring(0, 1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.darkBackgroundGray)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seller, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: repColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('⭐$reputation $tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: repColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
        ],
      ),
    );
  }

  Color _reputationColor(int reputation) {
    if (reputation >= 95) return const Color(0xFFD4A017);
    if (reputation >= 85) return const Color(0xFFA8A8A8);
    if (reputation >= 70) return const Color(0xFFCD7F32);
    if (reputation >= 60) return CupertinoColors.systemGrey;
    return CupertinoColors.destructiveRed;
  }

  String _reputationTier(int reputation) {
    if (reputation >= 95) return '金牌';
    if (reputation >= 85) return '银牌';
    if (reputation >= 70) return '铜牌';
    if (reputation >= 60) return '待改进';
    return '高风险';
  }

  Widget _buildAmountBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('金额明细', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildAmountRow('商品金额', _order.totalPrice),
          const SizedBox(height: 6),
          _buildAmountRow('运费', 0, free: true),
          const SizedBox(height: 8),
          Container(height: 1, color: CupertinoColors.systemGrey5),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('合计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('¥${_order.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CupertinoColors.destructiveRed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool free = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
        Text(
          free ? '免运费' : '¥${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: free ? CupertinoColors.systemGreen : CupertinoColors.black),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_order.status == 'paid') ...[
          CupertinoButton(
            onPressed: _showRefundConfirm,
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            color: CupertinoColors.systemOrange,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Text('申请仅退款', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
          ),
        ],
        if (_order.status == 'shipped') ...[
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: _showLogisticsDetail,
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  color: CupertinoColors.systemGrey4,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text('查看物流', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.darkBackgroundGray)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  onPressed: _showConfirmReceive,
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  color: CupertinoColors.systemGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text('确认收货', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                ),
              ),
            ],
          ),
        ],
        if (_order.status == 'received') ...[
          CupertinoButton(
            onPressed: _showReturnRefundConfirm,
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            color: CupertinoColors.systemOrange,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Text('申请退货退款', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
          ),
        ],
        if (_order.status == 'completed') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.checkmark_seal, size: 18, color: CupertinoColors.systemGreen),
                SizedBox(width: 6),
                Text('订单已完成，感谢您的购买', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CupertinoColors.systemGreen)),
              ],
            ),
          ),
        ],
        if (_order.status != 'completed') ...[
          const SizedBox(height: 10),
          CupertinoButton(
            onPressed: _navigateToDispute,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: CupertinoColors.systemGrey4,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.shield_fill, size: 16, color: CupertinoColors.systemGrey),
                SizedBox(width: 6),
                Text('申请仲裁', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _navigateToDispute() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const MallDisputePage()),
    );
  }

  void _showRefundConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('申请仅退款'),
        content: const Text('订单尚未发货，您可以申请仅退款。\n\n确认申请退款？'),
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
              _showRefundReasonPicker();
            },
            child: const Text('申请退款'),
          ),
        ],
      ),
    );
  }

  void _showRefundReasonPicker() {
    final reasons = ['不想要了', '下错订单', '卖家迟迟不发货', '价格问题', '其他原因'];
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择退款原因'),
        actions: reasons.map((r) => CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(ctx).pop();
            OrderService.requestRefund(_order.orderId, r);
            _showRefundSubmitted();
          },
          child: Text(r),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showRefundSubmitted() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('退款申请已提交'),
        content: const Text('您的退款申请已提交，卖家将在 48 小时内处理。\n\n如卖家拒绝，您可以申请仲裁。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showConfirmReceive() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认收货'),
        content: const Text('确认已收到商品？\n\n确认后订单将变更为已收货状态。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              OrderService.receiveOrder(_order.orderId);
            },
            child: const Text('确认收货'),
          ),
        ],
      ),
    );
  }

  void _showLogisticsDetail() {
    final info = _order.trackingNumber != null && _order.trackingNumber!.isNotEmpty
        ? '快递单号：${_order.trackingNumber}\n\n物流状态：${_logisticsText(_order.logistics)}'
        : '物流状态：${_logisticsText(_order.logistics)}';
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('物流详情'),
        content: Text(info),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _logisticsText(String logistics) {
    switch (logistics) {
      case 'picked_up': return '已揽收';
      case 'transporting': return '运输中';
      case 'delivering': return '派送中';
      case 'signed': return '已签收';
      default: return '未知';
    }
  }

  void _showReturnRefundConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('申请退货退款'),
        content: const Text('您已确认收货，可以申请退货退款。\n\n确认申请？'),
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
              _showReturnReasonPicker();
            },
            child: const Text('申请退货退款'),
          ),
        ],
      ),
    );
  }

  void _showReturnReasonPicker() {
    final reasons = ['质量问题', '与描述不符', '发错货', '包装损坏', '其他原因'];
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择退货原因'),
        actions: reasons.map((r) => CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(ctx).pop();
            OrderService.requestReturn(_order.orderId, r);
            _showReturnSubmitted();
          },
          child: Text(r),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showReturnSubmitted() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('退货退款申请已提交'),
        content: const Text('您的退货退款申请已提交，卖家将在 48 小时内处理。\n\n如卖家拒绝，您可以申请仲裁。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showReportSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('举报订单'),
        message: const Text('如遇到问题订单，可以通过以下方式解决：'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToDispute();
            },
            child: const Text('申请仲裁'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              showCupertinoDialog(
                context: context,
                builder: (c) => CupertinoAlertDialog(
                  title: const Text('联系客服'),
                  content: const Text('客服电话：400-888-0000\n在线时间：09:00-21:00'),
                  actions: [
                    CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(), child: const Text('确定')),
                  ],
                ),
              );
            },
            child: const Text('联系客服'),
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
}
