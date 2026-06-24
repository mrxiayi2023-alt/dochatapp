import 'package:flutter/cupertino.dart';

class _OrderItem {
  final String id;
  final String goodsName;
  final String origin;
  final String dest;
  final String price;
  final String vehicle;
  final String weight;
  final String timeAgo;
  final String shipper;
  final int quoteCount;

  const _OrderItem({
    required this.id,
    required this.goodsName,
    required this.origin,
    required this.dest,
    required this.price,
    required this.vehicle,
    required this.weight,
    required this.timeAgo,
    required this.shipper,
    this.quoteCount = 0,
  });
}

const _shipperOrders = [
  _OrderItem(id: 'HY20240624001', goodsName: '搬家家电', origin: '上海市浦东新区', dest: '上海市徐汇区', price: '¥180', vehicle: '小面', weight: '≤100kg', timeAgo: '10min前', shipper: '我', quoteCount: 3),
  _OrderItem(id: 'HY20240624002', goodsName: '建材配送', origin: '上海市闵行区', dest: '上海市宝山区', price: '¥350', vehicle: '厢货', weight: '500kg-1吨', timeAgo: '25min前', shipper: '我', quoteCount: 5),
  _OrderItem(id: 'HY20240624003', goodsName: '家具运输', origin: '上海市松江区', dest: '上海市黄浦区', price: '¥260', vehicle: '平板', weight: '100-500kg', timeAgo: '1h前', shipper: '我', quoteCount: 2),
];

const _availableOrders = [
  _OrderItem(id: 'HY20240624004', goodsName: '办公设备', origin: '上海市静安区', dest: '上海市杨浦区', price: '¥220', vehicle: '中面', weight: '≤100kg', timeAgo: '5min前', shipper: '刘先生'),
  _OrderItem(id: 'HY20240624005', goodsName: '生鲜食材', origin: '上海市普陀区', dest: '上海市长宁区', price: '¥150', vehicle: '冷藏', weight: '100-500kg', timeAgo: '12min前', shipper: '陈先生'),
  _OrderItem(id: 'HY20240624006', goodsName: '五金配件', origin: '上海市嘉定区', dest: '上海市虹口区', price: '¥180', vehicle: '小面', weight: '≤100kg', timeAgo: '20min前', shipper: '赵女士'),
  _OrderItem(id: 'HY20240624007', goodsName: '家电配送', origin: '上海市宝山区', dest: '上海市闵行区', price: '¥280', vehicle: '厢货', weight: '100-500kg', timeAgo: '30min前', shipper: '孙先生'),
  _OrderItem(id: 'HY20240624008', goodsName: '建筑材料', origin: '上海市奉贤区', dest: '上海市浦东新区', price: '¥400', vehicle: '平板', weight: '1-3吨', timeAgo: '1h前', shipper: '周先生'),
];

class _Quote {
  final String driverName;
  final String plate;
  final String vehicle;
  final double rating;
  final String price;
  final String time;
  final bool isSelected;

  const _Quote({
    required this.driverName,
    required this.plate,
    required this.vehicle,
    required this.rating,
    required this.price,
    required this.time,
    this.isSelected = false,
  });
}

const _mockQuotes = [
  _Quote(driverName: '张师傅', plate: '沪A·88888', vehicle: '小面', rating: 4.9, price: '¥168', time: '10分钟', isSelected: true),
  _Quote(driverName: '李师傅', plate: '沪B·66666', vehicle: '小面', rating: 4.8, price: '¥175', time: '15分钟'),
  _Quote(driverName: '王师傅', plate: '沪C·12345', vehicle: '中面', rating: 4.7, price: '¥190', time: '12分钟'),
];

class LogisticsOrderPage extends StatefulWidget {
  const LogisticsOrderPage({super.key});
  @override
  State<LogisticsOrderPage> createState() => _LogisticsOrderPageState();
}

class _LogisticsOrderPageState extends State<LogisticsOrderPage> {
  bool _isShipperView = true;
  int? _expandedOrderIndex;
  final Map<String, String> _quotePrices = {};
  final Map<String, bool> _quotedMap = {};

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('订单中心'),
        trailing: GestureDetector(
          onTap: () => _toggleRole(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isShipperView ? CupertinoIcons.person_fill : CupertinoIcons.hammer_fill,
                size: 16,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 4),
              Text(
                _isShipperView ? '货主' : '司机',
                style: const TextStyle(fontSize: 13, color: CupertinoColors.activeBlue),
              ),
              const Icon(CupertinoIcons.chevron_down, size: 10, color: CupertinoColors.activeBlue),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isShipperView ? CupertinoIcons.tray_full_fill : CupertinoIcons.hammer_fill,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isShipperView ? '货主视角：查看我发布的货源及司机报价' : '司机视角：查看可接订单并报价',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.activeBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _isShipperView ? _shipperOrders.length : _availableOrders.length,
                itemBuilder: (context, index) {
                  final orders = _isShipperView ? _shipperOrders : _availableOrders;
                  final order = orders[index];
                  return _buildOrderCard(order, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRole() {
    showCupertinoSheet(
      context: context,
      builder: (ctx) => CupertinoActionSheet(  // ignore: deprecated_member_use
        title: const Text('切换视角'),
        message: const Text('选择您要查看的订单视图'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isShipperView = true);
            },
            child: const Text('🧑‍💼 货主视角 - 我的发布与报价'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isShipperView = false);
            },
            child: const Text('🧑‍🔧 司机视角 - 可接订单'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(_OrderItem order, int index) {
    final isExpanded = _expandedOrderIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedOrderIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(order.vehicle, style: const TextStyle(fontSize: 11, color: CupertinoColors.activeBlue, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(order.weight, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemOrange, fontWeight: FontWeight.w500)),
                      ),
                      const Spacer(),
                      Text(order.timeAgo, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(order.goodsName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.square_fill, size: 6, color: CupertinoColors.systemOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(' → ', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(order.price, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CupertinoColors.systemOrange)),
                      const Spacer(),
                      if (_isShipperView)
                        Text('位司机报价', style: const TextStyle(fontSize: 12, color: CupertinoColors.activeBlue))
                      else
                        Text(order.shipper, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                        size: 14,
                        color: CupertinoColors.systemGrey3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: CupertinoColors.systemGrey5),
            if (_isShipperView)
              _buildShipperDetail(index)
            else
              _buildDriverDetail(index),
          ],
        ],
      ),
    );
  }

  Widget _buildShipperDetail(int orderIndex) {
    
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('司机报价', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('人报价', style: const TextStyle(fontSize: 10, color: CupertinoColors.activeBlue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_mockQuotes.length, (i) {
            final q = _mockQuotes[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: q.isSelected ? CupertinoColors.systemGreen.withValues(alpha: 0.06) : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
                border: q.isSelected ? Border.all(color: CupertinoColors.systemGreen.withValues(alpha: 0.3)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(q.driverName[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemGreen)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(q.driverName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.star_fill, size: 10, color: CupertinoColors.systemYellow),
                                const SizedBox(width: 2),
                                Text('', style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                              ],
                            ),
                          ],
                        ),
                        Text(' · ', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(q.price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CupertinoColors.systemOrange)),
                      Text('约到达', style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  if (q.isSelected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('已选', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                    ),
                  ],
                ],
              ),
            );
          }),
          CupertinoButton(
            onPressed: () => _showToast('已通知选中司机，等待确认中...'),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Text('确认选择', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetail(int index) {
    final order = _availableOrders[index];
    final orderId = order.id;
    final hasQuoted = _quotedMap[orderId] ?? false;
    

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('报价信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('货主：', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              Text(order.shipper, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              const Text('参考价：', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              Text(order.price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.systemOrange)),
            ],
          ),
          const SizedBox(height: 12),
          if (hasQuoted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.check_mark_circled_solid, size: 18, color: CupertinoColors.systemGreen),
                  const SizedBox(width: 8),
                  Text('您已报价 ¥，等待货主确认', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGreen, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Text('我的报价：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Text('¥ ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.systemOrange)),
                SizedBox(
                  width: 100,
                  child: CupertinoTextField(
                    placeholder: '输入报价',
                    placeholderStyle: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4.withValues(alpha: 0.5))),
                    ),
                    onChanged: (v) => _quotePrices[orderId] = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: () => _handleQuote(orderId),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: CupertinoColors.activeBlue,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text('提交报价', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            ),
          ],
        ],
      ),
    );
  }

  void _handleQuote(String orderId) {
    final price = _quotePrices[orderId] ?? '';
    if (price.trim().isEmpty) {
      _showToast('请输入报价金额');
      return;
    }
    setState(() => _quotedMap[orderId] = true);
    _showToast('报价已提交！等待货主回复中...');
  }

  void _showToast(String message) {
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
