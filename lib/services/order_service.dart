import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'cart_service.dart';
import '../pages/mall_page.dart';

class OrderInfo {
  final String orderId;
  final List<CartEntry> items;
  final double totalPrice;
  final DateTime createdAt;
  String status; // paid, shipped, received, completed
  String logistics; // picked_up, transporting, delivering, signed
  String? trackingNumber;
  String? refundReason;
  String? refundStatus; // null, submitted, rejected, approved
  String? returnReason;
  String? returnStatus; // null, submitted, rejected, approved

  OrderInfo({
    required this.orderId,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    this.status = 'paid',
    this.logistics = 'picked_up',
    this.trackingNumber,
    this.refundReason,
    this.refundStatus,
    this.returnReason,
    this.returnStatus,
  });

  int get totalCount {
    int c = 0;
    for (final e in items) { c += e.quantity; }
    return c;
  }
}

class OrderService {
  OrderService._();

  static final List<OrderInfo> _orders = [];

  /// Pre-populated demo orders for demonstration
  static void _ensureDemoOrders() {
    if (_orders.isEmpty) {
      final now = DateTime.now();
      // Demo order 1: received (completed flow)
      final demo1 = OrderInfo(
        orderId: 'ORD${now.millisecondsSinceEpoch.toString().substring(5)}',
        items: [CartEntry(product: _findProduct('手机壳'), quantity: 2)],
        totalPrice: 30,
        createdAt: now.subtract(const Duration(days: 5)),
        status: 'completed',
        logistics: 'signed',
        trackingNumber: 'SF1234567890',
      );
      // Demo order 2: shipped
      final demo2 = OrderInfo(
        orderId: 'ORD${(now.millisecondsSinceEpoch + 1).toString().substring(5)}',
        items: [
          CartEntry(product: _findProduct('东北大米'), quantity: 1),
          CartEntry(product: _findProduct('土蜂蜜'), quantity: 2),
        ],
        totalPrice: 171,
        createdAt: now.subtract(const Duration(days: 2)),
        status: 'shipped',
        logistics: 'delivering',
        trackingNumber: 'YT9876543210',
      );
      // Demo order 3: paid
      final demo3 = OrderInfo(
        orderId: 'ORD${(now.millisecondsSinceEpoch + 2).toString().substring(5)}',
        items: [CartEntry(product: _findProduct('保温杯'), quantity: 1)],
        totalPrice: 29,
        createdAt: now.subtract(const Duration(hours: 3)),
        status: 'paid',
        logistics: 'picked_up',
      );
      _orders.addAll([demo3, demo2, demo1]);
    }
  }

  static final Map<String, MallProduct> _productCache = {};

  static MallProduct _findProduct(String name) {
    // Products are defined in mall_page.dart but we can't import that here
    // Use a simple lookup with the same data
    if (_productCache.isEmpty) {
      final products = [
        _makeProduct('手机壳', '15', '', '\u{1F4F1}', Color(0xFFE3F2FD), '闲置二手', '数码', '小王', 95, 3.2),
        _makeProduct('耳机', '89', '', '\u{1F3A7}', Color(0xFFE8F5E9), '闲置二手', '数码', '小李', 98, 1.5),
        _makeProduct('机械键盘', '120', '', '\u{2328}', Color(0xFFFFF3E0), '闲置二手', '数码', '小张', 92, 5.8),
        _makeProduct('红富士苹果', '8', '/斤', '\u{1F34E}', Color(0xFFFFEBEE), '农副产品', '水果', '果农老赵', 99, 12.3),
        _makeProduct('东北大米', '35', '/袋', '\u{1F33E}', Color(0xFFFFFDE7), '农副产品', '粮食', '米农老钱', 97, 45.6),
        _makeProduct('土蜂蜜', '68', '/瓶', '\u{1F36F}', Color(0xFFF9FBE7), '农副产品', '特产', '蜂农老孙', 96, 28.7),
        _makeProduct('家纺四件套', '89', '', '\u{1F6CF}', Color(0xFFEDE7F6), '工厂直销', '家纺', '家纺工厂', 94, 8.9),
        _makeProduct('保温杯', '29', '', '\u{2615}', Color(0xFFE0F2F1), '工厂直销', '杯具', '杯具工厂', 93, 15.4),
        _makeProduct('拖鞋', '15', '', '\u{1F45F}', Color(0xFFFCE4EC), '工厂直销', '鞋履', '鞋履工厂', 91, 22.1),
      ];
      for (final p in products) { _productCache[p.name] = p; }
    }
    return _productCache[name]!;
  }

  static MallProduct _makeProduct(String name, String price, String unit, String emoji, Color bg, String tab, String cat, String seller, int rep, double dist) {
    return MallProduct(name: name, price: price, unit: unit, emoji: emoji, bgColor: bg, tab: tab, category: cat, seller: seller, reputation: rep, description: '', distance: dist);
  }

  static List<OrderInfo> get orders {
    _ensureDemoOrders();
    return _orders;
  }

  static List<OrderInfo> getOrdersByStatus(String status) {
    _ensureDemoOrders();
    if (status == '全部') return List.from(_orders);
    return _orders.where((o) => o.status == status).toList();
  }

  static void placeOrder(List<CartEntry> items, double totalPrice) {
    _ensureDemoOrders();
    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final order = OrderInfo(
      orderId: orderId,
      items: List.from(items),
      totalPrice: totalPrice,
      createdAt: DateTime.now(),
      status: 'paid',
      logistics: 'picked_up',
    );
    _orders.insert(0, order);
    CartService.clear();
    _notify();
  }

  static void shipOrder(String orderId, {String? trackingNumber}) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.status = 'shipped';
    order.logistics = 'transporting';
    if (trackingNumber != null) order.trackingNumber = trackingNumber;
    _notify();
  }

  static void updateLogistics(String orderId, String logistics) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.logistics = logistics;
    if (logistics == 'signed') {
      order.status = 'received';
    }
    _notify();
  }

  static void receiveOrder(String orderId) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.status = 'received';
    order.logistics = 'signed';
    _notify();
  }

  static void completeOrder(String orderId) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.status = 'completed';
    _notify();
  }

  static void requestRefund(String orderId, String reason) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.refundReason = reason;
    order.refundStatus = 'submitted';
    _notify();
  }

  static void rejectRefund(String orderId) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.refundStatus = 'rejected';
    _notify();
  }

  static void approveRefund(String orderId) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.refundStatus = 'approved';
    _notify();
  }

  static void requestReturn(String orderId, String reason) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.returnReason = reason;
    order.returnStatus = 'submitted';
    _notify();
  }

  static void rejectReturn(String orderId) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.returnStatus = 'rejected';
    _notify();
  }

  static void approveReturn(String orderId) {
    final order = _orders.firstWhere((o) => o.orderId == orderId);
    order.returnStatus = 'approved';
    _notify();
  }

  static void clearOrder(String orderId) {
    _orders.removeWhere((o) => o.orderId == orderId);
    _notify();
  }

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static void _notify() {
    changeNotifier.value = Random().nextInt(100000);
  }
}

