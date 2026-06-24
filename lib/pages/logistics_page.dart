import 'package:flutter/cupertino.dart';
import 'logistics_publish_page.dart';
import 'logistics_driver_verify_page.dart';
import 'logistics_order_page.dart';
import 'logistics_dispute_page.dart';

class _TabInfo {
  final String label;
  final String subtitle;
  const _TabInfo({required this.label, required this.subtitle});
}

const _tabs = [
  _TabInfo(label: '同城货运', subtitle: '30km内·即时送达'),
  _TabInfo(label: '长途货运', subtitle: '跨城运输·量大从优'),
  _TabInfo(label: '同城出行', subtitle: '乘客拼车·即将上线'),
];

class LogisticsPage extends StatefulWidget {
  const LogisticsPage({super.key});
  @override
  State<LogisticsPage> createState() => _LogisticsPageState();
}

class _LogisticsPageState extends State<LogisticsPage> {
  int _selectedTab = 0;
  final _originController = TextEditingController();
  final _destController = TextEditingController();

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.location_solid, size: 16, color: CupertinoColors.activeBlue),
            const SizedBox(width: 4),
            const Text('上海市', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 12, color: CupertinoColors.systemGrey),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _showRoleSwitch(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.person_fill, size: 18, color: CupertinoColors.activeBlue),
              SizedBox(width: 4),
              Text('切换角色', style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue)),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Column(
            children: [
              Icon(CupertinoIcons.circle_fill, size: 8, color: CupertinoColors.activeBlue),
              SizedBox(height: 2),
              Icon(CupertinoIcons.chevron_down, size: 6, color: CupertinoColors.systemGrey3),
              SizedBox(height: 2),
              Icon(CupertinoIcons.square_fill, size: 8, color: CupertinoColors.systemOrange),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoTextField(
                  controller: _originController,
                  placeholder: '输入出发地',
                  placeholderStyle: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                  style: const TextStyle(fontSize: 14),
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                Container(height: 1, color: CupertinoColors.systemGrey5),
                CupertinoTextField(
                  controller: _destController,
                  placeholder: '输入目的地',
                  placeholderStyle: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                  style: const TextStyle(fontSize: 14),
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.arrow_swap, size: 20, color: CupertinoColors.systemGrey),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          final isComingSoon = i == 2;
          return Expanded(
            child: GestureDetector(
              onTap: isComingSoon ? () => _showComingSoon(context) : () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? CupertinoColors.white : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tabs[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : (isComingSoon
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.darkBackgroundGray),
                      ),
                    ),
                    if (isComingSoon) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('预留', style: TextStyle(fontSize: 8, color: CupertinoColors.systemGrey)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildCityFreight();
      case 1:
        return _buildLongFreight();
      case 2:
        return _buildRidePool();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCityFreight() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildSectionHeader('附近货源', CupertinoIcons.cube_box),
        const SizedBox(height: 8),
        ...[
          _buildOrderCard('搬家家电', '上海市浦东新区', '上海市徐汇区', '¥180', '3.2km', '小面', '10min前'),
          _buildOrderCard('建材配送', '上海市闵行区', '上海市宝山区', '¥350', '8.5km', '厢货', '25min前'),
          _buildOrderCard('家具运输', '上海市松江区', '上海市黄浦区', '¥260', '12km', '平板', '1h前'),
        ],
        const SizedBox(height: 16),
        _buildSectionHeader('热招司机', CupertinoIcons.person_2_fill),
        const SizedBox(height: 8),
        _buildDriverCard('张师傅', '沪A·88888', '厢货', 4.9, '已完成 326 单'),
        const SizedBox(height: 8),
        _buildDriverCard('李师傅', '沪B·66666', '平板', 4.8, '已完成 218 单'),
        const SizedBox(height: 8),
        _buildDriverCard('王师傅', '沪C·12345', '小面', 4.7, '已完成 157 单'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLongFreight() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildSectionHeader('跨城货源', CupertinoIcons.map_fill),
        const SizedBox(height: 8),
        ...[
          _buildOrderCard('电子元件', '上海市', '深圳市', '¥3,200', '1,200km', '厢货', '30min前'),
          _buildOrderCard('服装包裹', '上海市', '北京市', '¥2,800', '1,100km', '平板', '1h前'),
          _buildOrderCard('机械设备', '苏州市', '广州市', '¥4,500', '1,300km', '平板', '2h前'),
        ],
        const SizedBox(height: 16),
        _buildSectionHeader('长途专线', CupertinoIcons.arrow_2_circlepath),
        const SizedBox(height: 8),
        _buildLineCard('上海→深圳', '每日发车', '¥1,200/吨', '2天到达'),
        const SizedBox(height: 8),
        _buildLineCard('上海→北京', '隔日发车', '¥1,000/吨', '1.5天到达'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRidePool() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.car_detailed, size: 64, color: CupertinoColors.systemGrey4),
            const SizedBox(height: 16),
            const Text('同城出行', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
            const SizedBox(height: 8),
            const Text('乘客拼车·顺路带人\n即将上线，敬请期待', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionItem(CupertinoIcons.square_list_fill, '发布货源', () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => const LogisticsPublishPage()  // ignore: deprecated_member_use,
            ));
          }),
          _actionItem(CupertinoIcons.doc_checkmark_fill, '司机认证', () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => const LogisticsDriverVerifyPage()  // ignore: deprecated_member_use,
            ));
          }),
          _actionItem(CupertinoIcons.tray_full_fill, '订单列表', () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => const LogisticsOrderPage()  // ignore: deprecated_member_use,
            ));
          }),
          _actionItem(CupertinoIcons.hand_raised_fill, '争议仲裁', () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => const LogisticsDisputePage()  // ignore: deprecated_member_use,
            ));
          }),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: CupertinoColors.activeBlue),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: CupertinoColors.darkBackgroundGray)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CupertinoColors.activeBlue),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildOrderCard(String goods, String origin, String dest, String price, String distance, String vehicle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
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
                child: Text(vehicle, style: const TextStyle(fontSize: 11, color: CupertinoColors.activeBlue, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.systemOrange)),
              const Spacer(),
              Text(time, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.circle_fill, size: 6, color: CupertinoColors.activeBlue),
              const SizedBox(width: 6),
              Expanded(child: Text(goods, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Text(distance, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.square_fill, size: 6, color: CupertinoColors.systemOrange),
              const SizedBox(width: 6),
              Expanded(child: Text(' → ', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(String name, String plate, String vehicle, double rating, String stats) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(name[0], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.systemGreen)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('已认证', style: TextStyle(fontSize: 9, color: CupertinoColors.systemGreen, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(' · ', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.star_fill, size: 12, color: CupertinoColors.systemYellow),
                  const SizedBox(width: 2),
                  Text('', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(stats, style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(String route, String frequency, String price, String duration) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18, color: CupertinoColors.systemOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(frequency, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange)),
              Text(duration, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('即将上线'),
        content: const Text('该功能正在开发中，敬请期待'),
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

  void _showRoleSwitch(BuildContext context) {
    showCupertinoSheet(
      context: context,
      builder: (ctx) => CupertinoActionSheet(  // ignore: deprecated_member_use
        title: const Text('切换角色'),
        message: const Text('选择您要使用的身份'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.of(ctx).pop(); },
            child: const Text('🧑‍💼 我是货主', style: TextStyle(fontSize: 16)),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.of(ctx).pop(); },
            child: const Text('🧑‍🔧 我是司机', style: TextStyle(fontSize: 16)),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () { Navigator.of(ctx).pop(); },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
