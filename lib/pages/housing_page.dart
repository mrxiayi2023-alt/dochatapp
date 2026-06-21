import 'package:flutter/cupertino.dart';
import 'housing_detail_page.dart';
import 'housing_publish_page.dart';
import 'housing_map_page.dart';
import 'housing_history_page.dart';
import '../services/housing_service.dart';

class HouseItem {
  final String title;
  final String area;
  final String price;
  final String size;
  final String layout;
  final String decoration;
  final String district;
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
    this.listingId = '',
    this.verificationStatus = 'verified',
    this.publisherType = '个人',
    this.companyName,
  });
}

List<HouseItem> _toHouseItems(List<HousingListing> listings) {
  return listings.map((l) => HouseItem(
    title: l.title,
    area: l.district,
    price: l.price.toStringAsFixed(0),
    size: '${l.size.toStringAsFixed(0)}m²',
    layout: l.layout,
    decoration: l.decoration,
    district: l.district,
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
  String _selectedDistrict = '全部';
  String _selectedDistance = '不限';
  String _selectedPrice = '不限';
  String _selectedLayout = '全部';
  bool _filterExpanded = false;
  bool _favoritesOnly = false;

  static const _districts = ['全部', '邗江区', '广陵区', '开发区', '江都区', '其他'];
  static const _distances = ['3km', '5km', '10km', '20km', '不限'];
  static const _prices = ['1000以下', '1000-2000', '2000-3000', '3000-5000', '5000以上', '不限'];
  static const _layouts = ['全部', '1室', '2室', '3室', '4室及以上'];

  String get _filterSummary {
    final parts = <String>[];
    if (_selectedDistrict != '全部') parts.add(_selectedDistrict);
    if (_selectedDistance != '不限') parts.add(_selectedDistance);
    if (_selectedPrice != '不限') parts.add(_selectedPrice);
    if (_selectedLayout != '全部') parts.add(_selectedLayout);
    if (_favoritesOnly) parts.add('仅收藏');
    return parts.isEmpty ? '全部' : parts.join('·');
  }

  List<HouseItem> get _filtered {
    var list = _toHouseItems(HousingService.listings);
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((h) => h.title.contains(query) || h.area.contains(query)).toList();
    }
    if (_favoritesOnly) {
      list = list.where((h) => HousingService.isFavorite(h.listingId)).toList();
    }
    if (_selectedDistrict != '全部') {
      if (_selectedDistrict == '其他') {
        list = list.where((h) => !_districts.sublist(1, 5).contains(h.district)).toList();
      } else {
        list = list.where((h) => h.district == _selectedDistrict).toList();
      }
    }
    // Price filter
    if (_selectedPrice != '不限') {
      list = list.where((h) {
        final price = double.tryParse(h.price) ?? 0;
        switch (_selectedPrice) {
          case '1000以下':
            return price < 1000;
          case '1000-2000':
            return price >= 1000 && price < 2000;
          case '2000-3000':
            return price >= 2000 && price < 3000;
          case '3000-5000':
            return price >= 3000 && price < 5000;
          case '5000以上':
            return price >= 5000;
          default:
            return true;
        }
      }).toList();
    }
    // Layout filter
    if (_selectedLayout != '全部') {
      list = list.where((h) {
        switch (_selectedLayout) {
          case '1室':
            return h.layout.startsWith('1室');
          case '2室':
            return h.layout.startsWith('2室');
          case '3室':
            return h.layout.startsWith('3室');
          case '4室及以上':
            final roomCount = int.tryParse(h.layout.substring(0, 1)) ?? 0;
            return roomCount >= 4;
          default:
            return true;
        }
      }).toList();
    }
    // Distance filter (placeholder — requires geolocation integration for real distances)
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: ValueListenableBuilder<int>(
        valueListenable: HousingService.changeNotifier,
        builder: (context, _, _) {
          return CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('电波找房'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _showHistoryPage,
                      child: const SizedBox(
                        width: 36, height: 36,
                        child: Icon(CupertinoIcons.clock, size: 22, color: CupertinoColors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showPublishPage,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(CupertinoIcons.add, size: 20, color: CupertinoColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFilterSection()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildHouseCard(_filtered[index]),
                  childCount: _filtered.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
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

  // ---- Collapsible filter section ----
  Widget _buildFilterSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _filterExpanded = !_filterExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filterExpanded ? CupertinoColors.activeBlue.withValues(alpha: 0.08) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _filterExpanded ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.line_horizontal_3_decrease, size: 16, color: _filterExpanded ? CupertinoColors.activeBlue : CupertinoColors.systemGrey),
                      const SizedBox(width: 6),
                      Text('筛选', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _filterExpanded ? CupertinoColors.activeBlue : CupertinoColors.black)),
                      const SizedBox(width: 6),
                      Text(_filterSummary, style: TextStyle(fontSize: 11, color: _filterExpanded ? CupertinoColors.activeBlue.withValues(alpha: 0.7) : CupertinoColors.systemGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      AnimatedRotation(turns: _filterExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 200), child: Icon(CupertinoIcons.chevron_down, size: 12, color: _filterExpanded ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)),
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
            ],
          ),
        ),
        // Favorites toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('仅看收藏', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                child: Container(
                  width: 42, height: 26,
                  decoration: BoxDecoration(
                    color: _favoritesOnly ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 150),
                        alignment: _favoritesOnly ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 22, height: 22,
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: CupertinoColors.white, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _filterExpanded
              ? Column(
                  children: [
                    _buildChipRow('区域', _districts, _selectedDistrict, (v) => setState(() { _selectedDistrict = v; _filterExpanded = false; })),
                    const SizedBox(height: 8),
                    _buildChipRow('距离', _distances, _selectedDistance, (v) => setState(() { _selectedDistance = v; _filterExpanded = false; })),
                    const SizedBox(height: 8),
                    _buildChipRow('价格', _prices, _selectedPrice, (v) => setState(() { _selectedPrice = v; _filterExpanded = false; })),
                    const SizedBox(height: 8),
                    _buildChipRow('户型', _layouts, _selectedLayout, (v) => setState(() { _selectedLayout = v; _filterExpanded = false; })),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildChipRow(String label, List<String> options, String selected, ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey)),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: options.map((o) {
              final isSelected = o == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelect(isSelected ? options.first : o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4),
                    ),
                    alignment: Alignment.center,
                    child: Text(o, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? CupertinoColors.white : CupertinoColors.black)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---- House card ----
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
                    Text(house.area, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('¥${house.price}/月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
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
