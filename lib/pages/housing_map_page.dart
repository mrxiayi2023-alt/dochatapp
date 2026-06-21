import 'package:flutter/cupertino.dart';
import '../services/housing_service.dart';
import 'housing_detail_page.dart';
import 'housing_page.dart';

class HousingMapPage extends StatefulWidget {
  const HousingMapPage({super.key});
  @override
  State<HousingMapPage> createState() => _HousingMapPageState();
}

class _HousingMapPageState extends State<HousingMapPage> {
  final _searchController = TextEditingController();

  List<HousingListing> get _listings {
    final query = _searchController.text.trim();
    if (query.isEmpty) return HousingService.listings;
    return HousingService.listings.where((l) =>
        l.title.contains(query) || l.district.contains(query) || l.layout.contains(query),
    ).toList();
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('地图找房'),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: HousingService.changeNotifier,
          builder: (context, _, _) {
            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: '搜索小区或区域',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                // Map placeholder
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CupertinoColors.systemGrey5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('\u{1F5FA}️', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              const Text(
                                '地图加载中，请接入高德SDK',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.darkBackgroundGray),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '预留高德地图 SDK 接口',
                                style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3),
                              ),
                            ],
                          ),
                        ),
                        // Simulated map markers
                        ..._listings.take(6).toList().asMap().entries.map((entry) {
                          final idx = entry.key;
                          final listing = entry.value;
                          final left = 0.15 + (idx % 3) * 0.3;
                          final top = 0.2 + (idx ~/ 3) * 0.3;
                          return Positioned(
                            left: MediaQuery.of(context).size.width * left,
                            top: MediaQuery.of(context).size.height * 0.06 + top * 100,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '¥${listing.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed),
                                  ),
                                ),
                                const Icon(CupertinoIcons.map_pin, size: 24, color: CupertinoColors.destructiveRed),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Bottom listing cards
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: _listings.isEmpty
                      ? const Center(child: Text('暂无匹配房源', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _listings.length,
                          itemBuilder: (context, index) => _buildMapCard(_listings[index]),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapCard(HousingListing listing) {
    // Create a compatible HouseItem for navigation
    final house = HouseItem(
      title: listing.title,
      area: listing.district,
      price: listing.price.toStringAsFixed(0),
      size: '${listing.size.toStringAsFixed(0)}m²',
      layout: listing.layout,
      decoration: listing.decoration,
      district: listing.district,
    );
    final isPending = listing.verificationStatus == 'pending';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => HousingDetailPage(house: house)),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: CupertinoColors.systemGrey4.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  const Icon(CupertinoIcons.house_fill, size: 28, color: CupertinoColors.systemGrey3),
                  if (isPending)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemOrange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('核验中', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: CupertinoColors.white)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(listing.district, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('¥${listing.price.toStringAsFixed(0)}/月', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
                      const SizedBox(width: 6),
                      Text('${listing.size.toStringAsFixed(0)}m²', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
