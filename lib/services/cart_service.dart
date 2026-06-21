// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年6月21日
// 文件说明：购物车状态管理（静态模拟）

import 'package:flutter/cupertino.dart';
import '../pages/mall_page.dart';

class CartEntry {
  final MallProduct product;
  int quantity;
  CartEntry({required this.product, this.quantity = 1});
}

class CartService {
  CartService._();

  static final Map<String, CartEntry> _items = {};

  static Map<String, CartEntry> get items => Map<String, CartEntry>.unmodifiable(_items);

  static int get totalCount {
    int count = 0;
    for (final entry in _items.values) {
      count += entry.quantity;
    }
    return count;
  }

  static double get totalPrice {
    double total = 0;
    for (final entry in _items.values) {
      total += double.parse(entry.product.price) * entry.quantity;
    }
    return total;
  }

  static void addItem(MallProduct product) {
    final key = product.name;
    if (_items.containsKey(key)) {
      _items[key]!.quantity++;
    } else {
      _items[key] = CartEntry(product: product);
    }
    _notify();
  }

  static void removeItem(String key) {
    _items.remove(key);
    _notify();
  }

  static void updateQuantity(String key, int quantity) {
    if (_items.containsKey(key)) {
      if (quantity <= 0) {
        _items.remove(key);
      } else {
        _items[key]!.quantity = quantity;
      }
      _notify();
    }
  }

  static void clear() {
    _items.clear();
    _notify();
  }

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static void _notify() {
    changeNotifier.value = totalCount;
  }
}
