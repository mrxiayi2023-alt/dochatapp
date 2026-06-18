import 'package:flutter/cupertino.dart';
import 'housing_detail_page.dart';

class HouseItem {
  final String title;
  final String area;
  final String price;
  final String size;
  final String layout;
  final String decoration;
  final String district;

  const HouseItem({
    required this.title,
    required this.area,
    required this.price,
    required this.size,
    required this.layout,
    required this.decoration,
    required this.district,
  });
}

const _demoHouses = [
  HouseItem(title: '阳光花园', area: '邗江区', price: '2500', size: '120m²', layout: '3室2厅', decoration: '简装', district: '邗江区'),
  HouseItem(title: '翠苑小区', area: '广陵区', price: '1800', size: '85m²', layout: '2室1厅', decoration: '精装', district: '广陵区'),
  HouseItem(title: '月亮湾', area: '邗江区', price: '1200', size: '50m²', layout: '1室1厅', decoration: '精装', district: '邗江区'),
  HouseItem(title: '金色家园', area: '开发区', price: '3500', size: '150m²', layout: '4室2厅', decoration: '豪装', district: '开发区'),
  HouseItem(title: '绿洲花苑', area: '广陵区', price: '2200', size: '100m²', layout: '3室1厅', decoration: '简装', district: '广陵区'),
  HouseItem(title: '星辰公寓', area: '邗江区', price: '2000', size: '90m²', layout: '2室2厅', decoration: '精装', district: '邗江区'),
];

class HousingPage extends StatefulWidget {
  const HousingPage({super.key});
  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  final _searchController = TextEditingController();
  String _selectedDistrict = '';

  List<HouseItem> get _filtered {
    var list = _demoHouses;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list.where((h) => h.title.contains(query) || h.area.contains(query)).toList();
    }
    if (_selectedDistrict.isNotEmpty) {
      list = list.where((h) => h.district == _selectedDistrict).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('电波找房'),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildHouseCard(_filtered[index]),
              childCount: _filtered.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
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

  Widget _buildFilterChips() {
    final districts = ['', '邗江区', '广陵区', '开发区'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterGroup('区域', districts, _selectedDistrict, (v) => setState(() => _selectedDistrict = v)),
        ],
      ),
    );
  }

  Widget _buildFilterGroup(String label, List<String> options, String selected, ValueChanged<String> onSelect) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ),
        const SizedBox(width: 4),
        ...options.where((o) => o.isNotEmpty).map((o) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => onSelect(selected == o ? '' : o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected == o ? CupertinoColors.activeBlue : CupertinoColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == o ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                ),
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontSize: 12,
                  color: selected == o ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildHouseCard(HouseItem house) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => HousingDetailPage(house: house)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.house_fill, size: 28, color: CupertinoColors.systemGrey3),
                    SizedBox(height: 4),
                    Text('图片占位', style: TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(house.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
            ],
          ),
        ),
      ),
    );
  }
}
