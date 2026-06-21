import 'package:flutter/cupertino.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'mall_order_detail_page.dart';

class MallCartPage extends StatefulWidget {
  const MallCartPage({super.key});
  @override
  State<MallCartPage> createState() => _MallCartPageState();
}

class _MallCartPageState extends State<MallCartPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('\u8d2d\u7269\u8f66'),
        trailing: CartService.totalCount > 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showClearConfirm,
                child: const Text('\u6e05\u7a7a', style: TextStyle(fontSize: 15, color: CupertinoColors.destructiveRed)),
              )
            : null,
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: CartService.changeNotifier,
          builder: (context, count, _) {
            if (CartService.items.isEmpty) return _buildEmptyState();
            return _buildCartContent();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.cart, size: 64, color: CupertinoColors.systemGrey3),
          const SizedBox(height: 16),
          const Text('\u8d2d\u7269\u8f66\u4e3a\u7a7a', style: TextStyle(fontSize: 17, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 8),
          const Text('\u53bb\u5546\u57ce\u901b\u901b\u5427', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey3)),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: const Text('\u53bb\u901b\u901b', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final items = CartService.items.entries.toList();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              return _buildCartItem(entry.key, entry.value);
            },
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildCartItem(String key, CartEntry entry) {
    final product = entry.product;
    final subtotal = double.parse(product.price) * entry.quantity;
    return Dismissible(
      key: Key(key),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        CartService.removeItem(key);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: product.bgColor, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(product.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('\u00a5${product.price}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
                      const Spacer(),
                      Text('\u5c0f\u8ba1 \u00a5${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildQuantityControl(key, entry.quantity),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(String key, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => CartService.updateQuantity(key, quantity - 1),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Icon(CupertinoIcons.minus, size: 14, color: CupertinoColors.systemGrey),
          ),
        ),
        Container(width: 32, alignment: Alignment.center, child: Text('$quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        GestureDetector(
          onTap: () => CartService.updateQuantity(key, quantity + 1),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(border: Border.all(color: CupertinoColors.activeBlue), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Icon(CupertinoIcons.plus, size: 14, color: CupertinoColors.activeBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Text('\u5408\u8ba1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text('¥${CartService.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CupertinoColors.destructiveRed)),
            const Spacer(),
            CupertinoButton(
              onPressed: _showCheckoutConfirm,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              color: CupertinoColors.activeBlue,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              pressedOpacity: 0.7,
              child: const Text('\u7ed3\u7b97', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('\u786e\u8ba4\u7ed3\u7b97'),
        content: Text('\u5171 ${CartService.totalCount} \u4ef6\u5546\u54c1\n\u5408\u8ba1 \u00a5${CartService.totalPrice.toStringAsFixed(0)}'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('\u53d6\u6d88')),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showPaymentSimulation();
            },
            child: const Text('\u786e\u8ba4\u7ed3\u7b97'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSimulation() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('\u652f\u4ed8\u786e\u8ba4'),
        content: Text('\u5e94\u4ed8\u91d1\u989d\uff1a\u00a5${CartService.totalPrice.toStringAsFixed(0)}\n\n\u786e\u8ba4\u652f\u4ed8\uff1f'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('\u53d6\u6d88')),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processPayment();
            },
            child: const Text('\u786e\u8ba4\u652f\u4ed8'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    final items = CartService.items.values.toList();
    final total = CartService.totalPrice;
    OrderService.placeOrder(items, total);
    final order = OrderService.orders.first;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('\u652f\u4ed8\u6210\u529f'),
        content: const Text('\u8ba2\u5355\u5df2\u751f\u6210\uff0c\u7b49\u5f85\u5356\u5bb6\u53d1\u8d27\u3002\n\n\u60a8\u53ef\u4ee5\u5728\u8ba2\u5355\u8be6\u60c5\u4e2d\u8ddf\u8e2a\u7269\u6d41\u72b6\u6001\u3002'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => MallOrderDetailPage(order: order)),
              );
            },
            child: const Text('\u67e5\u770b\u8ba2\u5355'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('\u786e\u5b9a'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('\u6e05\u7a7a\u8d2d\u7269\u8f66'),
        content: const Text('\u786e\u5b9a\u8981\u6e05\u7a7a\u8d2d\u7269\u8f66\u4e2d\u7684\u6240\u6709\u5546\u54c1\u5417\uff1f'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('\u53d6\u6d88')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () { CartService.clear(); Navigator.of(ctx).pop(); }, child: const Text('\u6e05\u7a7a')),
        ],
      ),
    );
  }
}
