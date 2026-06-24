import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'housing_detail_page.dart';
import 'housing_publish_page.dart';
import 'housing_map_page.dart';
import 'housing_history_page.dart';
import 'housing_favorites_page.dart';
import '../services/housing_service.dart';
import '../services/notification_service.dart';
import '../widgets/region_picker.dart';

class HouseItem {
  final String title;
  final String area;
  final String price;
  final String size;
  final String layout;
  final String decoration;
  final String district;
  final String province;
  final String areaDistrict;
  final String town;
  final String listingId;
  final String verificationStatus;
  final String publisherType;
  final String? companyName;

  const HouseItem({
    required this.title,
    required this.area,
    required this.price,
    required this.size,
    required this.layout,
    required this.decoration,
    required this.district,
    required this.province,
    required this.areaDistrict,
    this.town = '',
    this.listingId = '',
    this.verificationStatus = 'verified',
    this.publisherType = '个人',
    this.companyName,
  });

  /// 模拟距离（基于 listingId 的哈希值生成稳定距离）
  double get distanceKm {
    if (listingId.isEmpty) return (Random().nextDouble() * 10);
    return ((listingId.hashCode.abs() % 500) / 100.0);
  }

  /// 距离显示文本
  String get distanceText => '距你km';
}

List<HouseItem> _toHouseItems(List<HousingListing> listings) {
  return listings.map((l) => HouseItem(
    title: l.title,
    area: l.district,
    price: l.price.toStringAsFixed(0),
    size: 'm²',
    layout: l.layout,
    decoration: l.decoration,
    district: l.district,
    province: l.province,
    areaDistrict: l.area,
    town: l.town,
    listingId: l.id,
    verificationStatus: l.verificationStatus,
    publisherType: l.publisherType,
    companyName: l.companyName,
  )).toList();
}

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});
  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  final _searchController = TextEditingController();
  RegionSelection? _selectedRegion;
  String _selectedDistance = '不限';
  String _selectedPrice = '不限';
  String _selectedLayout = '不限';
  String _selectedAreaSize = '不限';
  String _selectedDecoration = '不限';
  String _selectedPublisherType = '不限';

  @override
  void initState() {
    super.initState();
    NotificationService.clearBadge('housing');
  }

  // ── 筛选常量 ──
  static const _distances = ['3km', '5km', '10km', '不限'];
  static const _prices = ['1000以下', '1000-2000', '2000-3000', '3000-5000', '5000以上', '不限'];
  static const _layouts = ['不限', '一室', '二室', '三室', '四室+', '别墅'];
  static const _areaSizes = ['不限', '50m²以下', '50-70m²', '70-90m²', '90-120m²', '120m²以上'];
  static const _decorations = ['不限', '毛坯', '简装', '精装', '豪装'];
  static const _publisherTypes = ['不限', '个人', '中介'];

  /// 筛选摘要
  String get _filterSummary {
    final parts = <String>[];
    if (_selectedRegion != null) parts.add(_selectedRegion!.shortPath);
    if (_selectedDistance != '不限') parts.add(_selectedDistance);
    if (_selectedPrice != '不限') parts.add(_selectedPrice);
    if (_selectedLayout != '不限') parts.add(_selectedLayout);
    if (_selectedAreaSize != '不限') parts.add(_selectedAreaSize);
    if (_selectedDecoration != '不限') parts.add(_selectedDecoration);
    if (_selectedPublisherType != '不限') parts.add(_selectedPublisherType);
    return parts.isEmpty ? '全部' : parts.join('·');
  }

  /// 是否启用了任何筛选
  bool get _hasActiveFilters =>
      _selectedRegion != null ||
      _selectedDistance != '不限' ||
      _selectedPrice != '不限' ||
      _selectedLayout != '不限' ||
      _selectedAreaSize != '不限' ||
      _selectedDecoration != '不限' ||
      _selectedPublisherType != '不限';

  /// 筛选后的房源列表
  List<HouseItem> get _filtered {
    var list = _toHouseItems(HousingService.listings);
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((h) => h.title.contains(query) || h.area.contains(query)).toList();
    }
    // 区域
    if (_selectedRegion != null) {
      list = list.where((h) => _selectedRegion!.matches(h.province, h.district, h.areaDistrict, h.town)).toList();
    }
    // 价格
    if (_selectedPrice != '不限') {
      list = list.where((h) {
        final price = double.tryParse(h.price) ?? 0;
        switch (_selectedPrice) {
          case '1000以下': return price < 1000;
          case '1000-2000': return price >= 1000 && price < 2000;
          case '2000-3000': return price >= 2000 && price < 3000;
          case '3000-5000': return price >= 3000 && price < 5000;
          case '5000以上': return price >= 5000;
          default: return true;
        }
      }).toList();
    }
    // 户型
    if (_selectedLayout != '不限') {
      list = list.where((h) {
        switch (_selectedLayout) {
          case '一室': return h.layout.startsWith('1');
          case '二室': return h.layout.startsWith('2');
          case '三室': return h.layout.startsWith('3');
          case '四室+':
            final roomCount = int.tryParse(h.layout.substring(0, 1)) ?? 0;
            return roomCount >= 4;
          case '别墅': return h.layout.contains('别墅');
          default: return true;
        }
      }).toList();
    }
    // 面积
    if (_selectedAreaSize != '不限') {
      list = list.where((h) {
        final size = double.tryParse(h.size.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        switch (_selectedAreaSize) {
          case '50m²以下': return size < 50;
          case '50-70m²': return size >= 50 && size < 70;
          case '70-90m²': return size >= 70 && size < 90;
          case '90-120m²': return size >= 90 && size < 120;
          case '120m²以上': return size >= 120;
          default: return true;
        }
      }).toList();
    }
    // 装修
    if (_selectedDecoration != '不限') {
      list = list.where((h) => h.decoration == _selectedDecoration).toList();
    }
    // 发布身份
    if (_selectedPublisherType != '不限') {
      list = list.where((h) => h.publisherType == _selectedPublisherType).toList();
    }
    // 距离筛选（用模拟距离过滤）
    if (_selectedDistance != '不限') {
      final km = int.tryParse(_selectedDistance.replaceAll('km', '')) ?? 0;
      list = list.where((h) => h.distanceKm <= km).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPublishPage() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const HousingPublishPage()),
    ).then((_) => setState(() {}));
  }

  void _showMapPage() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const HousingMapPage()),
    );
  }

  void _showHistoryPage() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const HousingHistoryPage()),
    );
  }

  void _showFavoritesPage() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const HousingFavoritesPage()),
    );
  }

  // ─────────────────────────────────────────────
  // 筛选 ActionSheet
  // ─────────────────────────────────────────────

  /// 打开筛选主菜单
  void _showFilterSheet() async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择筛选条件'),
        message: Text('当前：',
          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('region'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('区域', style: TextStyle(fontSize: 16)),
                Text(_selectedRegion?.shortPath ?? '不限',
                  style: TextStyle(fontSize: 14,
                    color: _selectedRegion != null ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('price'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('价格', style: TextStyle(fontSize: 16)),
                Text(_selectedPrice,
                  style: TextStyle(fontSize: 14,
                    color: _selectedPrice != '不限' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('layout'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('户型', style: TextStyle(fontSize: 16)),
                Text(_selectedLayout,
                  style: TextStyle(fontSize: 14,
                    color: _selectedLayout != '不限' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('areaSize'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('面积', style: TextStyle(fontSize: 16)),
                Text(_selectedAreaSize,
                  style: TextStyle(fontSize: 14,
                    color: _selectedAreaSize != '不限' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('decoration'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('装修', style: TextStyle(fontSize: 16)),
                Text(_selectedDecoration,
                  style: TextStyle(fontSize: 14,
                    color: _selectedDecoration != '不限' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('distance'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('距离', style: TextStyle(fontSize: 16)),
                Text(_selectedDistance,
                  style: TextStyle(fontSize: 14,
                    color: _selectedDistance != '不限' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('publisherType'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('发布身份', style: TextStyle(fontSize: 16)),
                Text(_selectedPublisherType,
                  style: TextStyle(fontSize: 14,
                    color: _selectedPublisherType != '不限' ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
              ],
            ),
          ),
          if (_hasActiveFilters)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop('reset'),
              child: const Text('重置全部筛选', style: TextStyle(fontSize: 16)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          isDefaultAction: true,
          child: const Text('完成', style: TextStyle(fontSize: 16)),
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'region':
        await _pickRegion();
        break;
      case 'price':
        await _pickOption('价格', _prices, (v) => _selectedPrice = v, _selectedPrice);
        break;
      case 'layout':
        await _pickOption('户型', _layouts, (v) => _selectedLayout = v, _selectedLayout);
        break;
      case 'areaSize':
        await _pickOption('面积', _areaSizes, (v) => _selectedAreaSize = v, _selectedAreaSize);
        break;
      case 'decoration':
        await _pickOption('装修', _decorations, (v) => _selectedDecoration = v, _selectedDecoration);
        break;
      case 'distance':
        await _pickOption('距离', _distances, (v) => _selectedDistance = v, _selectedDistance);
        break;
      case 'publisherType':
        await _pickOption('发布身份', _publisherTypes, (v) => _selectedPublisherType = v, _selectedPublisherType);
        break;
      case 'reset':
        setState(() {
          _selectedRegion = null;
          _selectedDistance = '不限';
          _selectedPrice = '不限';
          _selectedLayout = '不限';
          _selectedAreaSize = '不限';
          _selectedDecoration = '不限';
          _selectedPublisherType = '不限';
        });
        return;
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickRegion() async {
    final result = await RegionPicker.show(context, initial: _selectedRegion, maxDepth: 4);
    if (result != null && mounted) {
      setState(() => _selectedRegion = result);
    }
  }

  Future<void> _pickOption(String title, List<String> options, void Function(String) onSelect, String current) async {
    if (!mounted) return;
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('选择'),
        actions: [
          ...options.map((opt) {
            final isActive = opt == current;
            return CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(opt),
              child: Text(opt,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? CupertinoColors.activeBlue : CupertinoColors.black,
                ),
              ),
            );
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消', style: TextStyle(color: CupertinoColors.destructiveRed)),
        ),
      ),
    );
    if (selected != null) {
      onSelect(selected);
      if (mounted) setState(() {});
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('电波找房', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(onTap: _showFavoritesPage,
              child: const Icon(CupertinoIcons.heart, size: 22, color: CupertinoColors.systemGrey)),
            const SizedBox(width: 16),
            GestureDetector(onTap: _showHistoryPage,
              child: const Icon(CupertinoIcons.clock, size: 22, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: HousingService.changeNotifier,
          builder: (context, _, _) {
            final filtered = _filtered;
            return Column(
              children: [
                _buildSearchBar(),
                _buildFilterSection(),
                if (_hasActiveFilters) _buildActiveFilterBar(),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildHouseCard(filtered[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: '搜索小区或区域',
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hasActiveFilters ? CupertinoColors.activeBlue.withValues(alpha: 0.08) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasActiveFilters ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.line_horizontal_3_decrease, size: 16,
                    color: _hasActiveFilters ? CupertinoColors.activeBlue : CupertinoColors.systemGrey),
                  const SizedBox(width: 6),
                  Text('筛选', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _hasActiveFilters ? CupertinoColors.activeBlue : CupertinoColors.black)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(_filterSummary,
                      style: TextStyle(fontSize: 11,
                        color: _hasActiveFilters ? CupertinoColors.activeBlue.withValues(alpha: 0.7) : CupertinoColors.systemGrey),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_down, size: 12, color: CupertinoColors.systemGrey),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showMapPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.map, size: 14, color: CupertinoColors.activeBlue),
                  SizedBox(width: 4),
                  Text('地图找房', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.activeBlue)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showPublishPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.plus, size: 14, color: CupertinoColors.white),
                  SizedBox(width: 4),
                  Text('发布', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterBar() {
    final chips = <Widget>[];
    void addChip(String label, VoidCallback onRemove) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.activeBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CupertinoColors.activeBlue)),
                const SizedBox(width: 3),
                const Icon(CupertinoIcons.xmark_circle_fill, size: 12, color: CupertinoColors.activeBlue),
              ],
            ),
          ),
        ),
      ));
    }

    if (_selectedRegion != null) addChip(_selectedRegion!.shortPath, () => setState(() => _selectedRegion = null));
    if (_selectedPrice != '不限') addChip(_selectedPrice, () => setState(() => _selectedPrice = '不限'));
    if (_selectedLayout != '不限') addChip(_selectedLayout, () => setState(() => _selectedLayout = '不限'));
    if (_selectedAreaSize != '不限') addChip(_selectedAreaSize, () => setState(() => _selectedAreaSize = '不限'));
    if (_selectedDecoration != '不限') addChip(_selectedDecoration, () => setState(() => _selectedDecoration = '不限'));
    if (_selectedDistance != '不限') addChip(_selectedDistance, () => setState(() => _selectedDistance = '不限'));
    if (_selectedPublisherType != '不限') addChip(_selectedPublisherType, () => setState(() => _selectedPublisherType = '不限'));

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.house_alt, size: 56, color: CupertinoColors.systemGrey3),
          const SizedBox(height: 12),
          const Text('暂无匹配房源', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 8),
          const Text('试试调整筛选条件吧', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
        ],
      ),
    );
  }

  Widget _buildHouseCard(HouseItem house) {
    final isPending = house.verificationStatus == 'pending';
    final isFav = HousingService.isFavorite(house.listingId);
    final isAgent = house.publisherType == '中介';
    return GestureDetector(
      onTap: () {
        HousingService.recordBrowse(house.listingId);
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => HousingDetailPage(house: house)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: CupertinoColors.systemGrey4.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100, height: 80,
                    decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(8)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.house_fill, size: 28, color: CupertinoColors.systemGrey3),
                        SizedBox(height: 4),
                        Text('图片占位', style: TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  ),
                  if (isPending)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: CupertinoColors.systemOrange.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
                        child: const Text('核验中', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: CupertinoColors.white)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(house.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isPending)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: CupertinoColors.systemOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                            child: const Text('核验中', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange)),
                          ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAgent ? CupertinoColors.systemTeal.withValues(alpha: 0.12) : CupertinoColors.systemGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(isAgent ? '中介🏢' : '个人🏠', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isAgent ? CupertinoColors.systemTeal : CupertinoColors.systemGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(house.area, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(house.distanceText, style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('¥/月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
                        const SizedBox(width: 8),
                        Text(house.size, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                        const SizedBox(width: 8),
                        Text(house.layout, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => HousingService.toggleFavorite(house.listingId),
                          child: Icon(
                            isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                            size: 20,
                            color: isFav ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}