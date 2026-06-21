import 'package:flutter/cupertino.dart';
import 'mall_order_detail_page.dart';
import '../services/order_service.dart';

class MallOrderListPage extends StatefulWidget {
  const MallOrderListPage({super.key});
  @override
  State<MallOrderListPage> createState() => _MallOrderListPageState();
}

class _MallOrderListPageState extends State<MallOrderListPage> {
  String _selectedStatus = '全部';
  final _statuses = ['全部', '待发货', '已发货', '已收货', '已完成'];

  String _toApiStatus(String display) {
    switch (display) {
      case '待发货': return 'paid';
      case '已发货': return 'shipped';
      case '已收货': return 'received';
      case '已完成': return 'completed';
      default: return '全部';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('我的订单'),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: OrderService.changeNotifier,
          builder: (context, _, _) {
            final orders = OrderService.getOrdersByStatus(_toApiStatus(_selectedStatus));
            return Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: orders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 44,
      color: CupertinoColors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _statuses.map((status) {
          final selected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? CupertinoColors.white : CupertinoColors.darkBackgroundGray,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.doc_text, size: 56, color: CupertinoColors.systemGrey3),
          const SizedBox(height: 12),
          const Text('暂无订单', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderInfo order) {
    String statusText;
    Color statusColor;
    switch (order.status) {
      case 'paid': statusText = '待发货'; statusColor = CupertinoColors.systemOrange; break;
      case 'shipped': statusText = '已发货'; statusColor = CupertinoColors.activeBlue; break;
      case 'received': statusText = '已收货'; statusColor = CupertinoColors.systemGreen; break;
      case 'completed': statusText = '已完成'; statusColor = CupertinoColors.systemGrey; break;
      default: statusText = order.status; statusColor = CupertinoColors.systemGrey;
    }
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final timeStr = '${order.createdAt.month}月${order.createdAt.day}日 ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => MallOrderDetailPage(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (firstItem != null)
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: firstItem.product.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(firstItem.product.emoji, style: const TextStyle(fontSize: 30)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstItem != null ? firstItem.product.name : '商品',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (order.items.length > 1)
                    Text('等${order.totalCount}件商品', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('¥${order.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }
}

