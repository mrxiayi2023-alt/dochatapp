import 'package:flutter/cupertino.dart';
import 'mall_page.dart';
import 'mall_dispute_page.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';

class MallDetailPage extends StatefulWidget {
  final MallProduct product;
  const MallDetailPage({super.key, required this.product});

  @override
  State<MallDetailPage> createState() => _MallDetailPageState();
}

class _MallDetailPageState extends State<MallDetailPage> {
  String? _orderId;
  bool _isSellerView = false;
  final _trackingController = TextEditingController();

  MallProduct get product => widget.product;

  OrderInfo? _getOrder() {
    if (_orderId == null) return null;
    final idx = OrderService.orders.indexWhere((o) => o.orderId == _orderId);
    if (idx == -1) { _orderId = null; return null; }
    return OrderService.orders[idx];
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
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

  void _navigateToDispute() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const MallDisputePage()),
    );
  }

  void _showReportSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('举报商品'),
        message: Text('请选择举报「${product.name}」的原因'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.of(ctx).pop(); _showReportConfirm('虚假商品'); },
            child: const Text('虚假商品'),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.of(ctx).pop(); _showReportConfirm('描述不符'); },
            child: const Text('描述不符'),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.of(ctx).pop(); _showReportConfirm('价格欺诈'); },
            child: const Text('价格欺诈'),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.of(ctx).pop(); _showReportConfirm('其他'); },
            child: const Text('其他'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showReportConfirm(String reason) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('举报已提交'),
        content: Text('举报原因：$reason\n\n平台将在24小时内审核处理，感谢您的监督。'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  void _buyNow() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认购买'),
        content: Text('确认购买「${product.name}」？\n\n¥${product.price}${product.unit}'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processDirectBuy();
            },
            child: const Text('确认购买'),
          ),
        ],
      ),
    );
  }

  void _processDirectBuy() {
    final price = double.tryParse(product.price) ?? 0;
    final entry = CartEntry(product: product, quantity: 1);
    OrderService.placeOrder([entry], price);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _orderId = OrderService.orders.first.orderId;
        });
      }
    });
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('支付成功'),
        content: Text('已购买「${product.name}」\n¥${product.price}${product.unit}\n\n订单状态：待发货'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showShipDialog() {
    _trackingController.clear();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('卖家发货'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入快递单号（可选）'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _trackingController,
              placeholder: '快递单号',
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              final tracking = _trackingController.text.trim();
              OrderService.shipOrder(_orderId!, trackingNumber: tracking.isNotEmpty ? tracking : null);
              showCupertinoDialog(
                context: context,
                builder: (c) => CupertinoAlertDialog(
                  title: const Text('卖家已发货'),
                  content: tracking.isNotEmpty ? Text('快递单号：$tracking\n\n请耐心等待收货。') : const Text('卖家已发货，请耐心等待收货。'),
                  actions: [CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(), child: const Text('确定'))],
                ),
              );
            },
            child: const Text('确认发货'),
          ),
        ],
      ),
    );
  }

  void _confirmReceive() {
    OrderService.receiveOrder(_orderId!);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('已确认收货'),
        content: const Text('感谢您的购买！如有问题可申请退货退款。'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  void _requestRefund() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('申请仅退款'),
        message: const Text('请选择退款原因'),
        actions: [
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitRefund('质量问题'); }, child: const Text('质量问题')),
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitRefund('描述不符'); }, child: const Text('描述不符')),
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitRefund('不喜欢'); }, child: const Text('不喜欢')),
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitRefund('其他'); }, child: const Text('其他')),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
      ),
    );
  }

  void _submitRefund(String reason) {
    OrderService.requestRefund(_orderId!, reason);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('退款申请已提交'),
        content: Text('退款原因：$reason\n\n等待卖家处理中...'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  void _simulateSellerRejectRefund() {
    OrderService.rejectRefund(_orderId!);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('卖家已拒绝'),
        content: const Text('卖家拒绝了您的退款申请。\n如仍有争议，可申请平台仲裁。'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  void _requestReturn() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('申请退货退款'),
        message: const Text('请选择退货原因'),
        actions: [
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitReturn('质量问题'); }, child: const Text('质量问题')),
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitReturn('描述不符'); }, child: const Text('描述不符')),
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitReturn('不喜欢'); }, child: const Text('不喜欢')),
          CupertinoActionSheetAction(onPressed: () { Navigator.of(ctx).pop(); _submitReturn('其他'); }, child: const Text('其他')),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
      ),
    );
  }

  void _submitReturn(String reason) {
    OrderService.requestReturn(_orderId!, reason);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('退货退款申请已提交'),
        content: Text('退货原因：$reason\n\n等待卖家处理中...'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  void _simulateSellerRejectReturn() {
    OrderService.rejectReturn(_orderId!);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('卖家已拒绝'),
        content: const Text('卖家拒绝了您的退货申请。\n如仍有争议，可申请平台仲裁。'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showReportSheet,
          child: const Icon(CupertinoIcons.exclamationmark_bubble, size: 22, color: CupertinoColors.systemGrey),
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: OrderService.changeNotifier,
          builder: (context, _, _) {
            final order = _getOrder();
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageArea(),
                      _buildProductInfo(),
                      _buildSellerInfo(),
                      if (order != null) _buildOrderStatusCard(order),
                      if (order != null && (order.status == 'paid' || order.status == 'shipped'))
                        _buildRefundCard(order),
                      if (order != null && order.status == 'received')
                        _buildReturnCard(order),
                      _buildDescription(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 260,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(color: product.bgColor, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(product.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          const Text('商品图片占位', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('¥${product.price}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: CupertinoColors.destructiveRed)),
              if (product.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(product.unit, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey))),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text('分类: ${product.category}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    final repColor = _reputationColor(product.reputation);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('卖家信息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: CupertinoColors.systemTeal, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(product.seller.characters.first, style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.seller, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.star_fill, size: 14, color: repColor),
                        const SizedBox(width: 4),
                        Text('信誉分 ${product.reputation}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: repColor)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: repColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(_reputationTier(product.reputation), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: repColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.location, size: 12, color: CupertinoColors.systemGrey),
                        const SizedBox(width: 2),
                        Text('距你 ${product.distance}km', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey4)),
                        const SizedBox(width: 8),
                        const Text('南京市', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('联系卖家'),
                      content: Text('即将与「${product.seller}」发起聊天'),
                      actions: [CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.of(ctx).pop())],
                    ),
                  );
                },
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                color: CupertinoColors.activeBlue,
                pressedOpacity: 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text('联系卖家', style: TextStyle(color: CupertinoColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(OrderInfo order) {
    String statusText;
    Color statusColor;
    switch (order.status) {
      case 'paid': statusText = '待发货'; statusColor = CupertinoColors.systemOrange; break;
      case 'shipped': statusText = '已发货'; statusColor = CupertinoColors.activeBlue; break;
      case 'received': statusText = '已收货'; statusColor = CupertinoColors.systemGreen; break;
      case 'completed': statusText = '已完成'; statusColor = CupertinoColors.systemGrey; break;
      default: statusText = '未知'; statusColor = CupertinoColors.systemGrey;
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('订单状态', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('单号：${order.trackingNumber}', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
              ],
              const Spacer(),
              if (order.status == 'paid')
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onPressed: _showShipDialog,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  color: CupertinoColors.systemGrey4,
                  child: const Text('模拟发货', style: TextStyle(fontSize: 12)),
                ),
              if (order.status == 'shipped')
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onPressed: _confirmReceive,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  color: CupertinoColors.systemGreen,
                  child: const Text('确认收货', style: TextStyle(fontSize: 12, color: CupertinoColors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefundCard(OrderInfo order) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('退款/售后', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (order.refundStatus == null)
            CupertinoButton(
              onPressed: _requestRefund,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: CupertinoColors.systemOrange,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text('申请仅退款', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          if (order.refundStatus == 'submitted')
            _buildStatusRow('退款审核中', CupertinoColors.systemOrange, [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onPressed: _simulateSellerRejectRefund,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                color: CupertinoColors.destructiveRed,
                child: const Text('模拟卖家拒绝', style: TextStyle(fontSize: 11, color: CupertinoColors.white)),
              ),
            ]),
          if (order.refundStatus == 'rejected')
            _buildStatusRow('卖家已拒绝退款', CupertinoColors.destructiveRed, [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                onPressed: _navigateToDispute,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                color: CupertinoColors.systemOrange,
                child: const Text('申请仲裁', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
              ),
            ]),
          if (order.refundStatus == 'approved')
            _buildStatusRow('退款已通过', CupertinoColors.systemGreen, []),
          if (!_isSellerView && (order.refundStatus == 'submitted' || order.refundStatus == 'rejected'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => setState(() => _isSellerView = true),
                child: const Text('切换为卖家视角', style: TextStyle(fontSize: 12, color: CupertinoColors.activeBlue)),
              ),
            ),
          if (_isSellerView)
            _buildSellerRefundActions(order),
        ],
      ),
    );
  }

  Widget _buildSellerRefundActions(OrderInfo order) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('--- 卖家端视角 ---', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 8),
          Text(
            order.refundStatus == 'submitted' ? '买家申请仅退款，请处理' : '买家退款已被拒绝',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (order.refundStatus == 'submitted')
            Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onPressed: () => OrderService.approveRefund(_orderId!),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  color: CupertinoColors.systemGreen,
                  child: const Text('同意退款', style: TextStyle(fontSize: 12, color: CupertinoColors.white)),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onPressed: _simulateSellerRejectRefund,
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  color: CupertinoColors.destructiveRed,
                  child: const Text('拒绝退款', style: TextStyle(fontSize: 12, color: CupertinoColors.white)),
                ),
              ],
            ),
          if (order.refundStatus == 'rejected')
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              onPressed: _navigateToDispute,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              color: CupertinoColors.systemOrange,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.shield_fill, size: 14, color: CupertinoColors.white),
                  SizedBox(width: 4),
                  Text('申请仲裁（恶意退货）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                ],
              ),
            ),
          GestureDetector(
            onTap: () => setState(() => _isSellerView = false),
            child: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('返回买家视角', style: TextStyle(fontSize: 12, color: CupertinoColors.activeBlue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(OrderInfo order) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('退货/售后', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (order.returnStatus == null)
            CupertinoButton(
              onPressed: _requestReturn,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: CupertinoColors.systemOrange,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text('申请退货退款', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          if (order.returnStatus == 'submitted')
            _buildStatusRow('退货审核中', CupertinoColors.systemOrange, [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onPressed: _simulateSellerRejectReturn,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                color: CupertinoColors.destructiveRed,
                child: const Text('模拟卖家拒绝', style: TextStyle(fontSize: 11, color: CupertinoColors.white)),
              ),
            ]),
          if (order.returnStatus == 'rejected')
            _buildStatusRow('卖家已拒绝退货', CupertinoColors.destructiveRed, [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                onPressed: _navigateToDispute,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                color: CupertinoColors.systemOrange,
                child: const Text('申请仲裁', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
              ),
            ]),
          if (order.returnStatus == 'approved')
            _buildStatusRow('退货已通过', CupertinoColors.systemGreen, []),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String text, Color color, List<Widget> actions) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
        const Spacer(),
        ...actions,
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('商品描述', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(product.description, style: const TextStyle(fontSize: 15, color: CupertinoColors.darkBackgroundGray, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final order = _getOrder();
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order == null)
            CupertinoButton(
              onPressed: _buyNow,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text('立即购买', style: TextStyle(color: CupertinoColors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            )
          else
            CupertinoButton(
              onPressed: () {
                OrderService.clearOrder(_orderId!);
                setState(() => _orderId = null);
              },
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              color: CupertinoColors.systemGrey4,
              pressedOpacity: 0.7,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text('重置订单（演示用）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}
