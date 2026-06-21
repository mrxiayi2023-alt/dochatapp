import 'package:flutter/cupertino.dart';
import '../services/housing_service.dart';
import 'housing_detail_page.dart';
import 'housing_page.dart';

class HousingHistoryPage extends StatefulWidget {
  const HousingHistoryPage({super.key});
  @override
  State<HousingHistoryPage> createState() => _HousingHistoryPageState();
}

class _HousingHistoryPageState extends State<HousingHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('浏览历史'),
        trailing: ValueListenableBuilder<int>(
          valueListenable: HousingService.changeNotifier,
          builder: (context, _, _) {
            final history = HousingService.browseHistoryList;
            if (history.isEmpty) return const SizedBox.shrink();
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showClearConfirm,
              child: const Text('清空', style: TextStyle(fontSize: 15, color: CupertinoColors.destructiveRed)),
            );
          },
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: HousingService.changeNotifier,
          builder: (context, _, _) {
            final history = HousingService.browseHistoryList;
            if (history.isEmpty) return _buildEmptyState();
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) => _buildHistoryCard(history[index]),
            );
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
          const Icon(CupertinoIcons.clock, size: 56, color: CupertinoColors.systemGrey3),
          const SizedBox(height: 12),
          const Text('暂无浏览记录', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 8),
          const Text('浏览过的房源会出现在这里', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey3)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HousingListing listing) {
    final house = HouseItem(
      title: listing.title,
      area: listing.district,
      price: listing.price.toStringAsFixed(0),
      size: '${listing.size.toStringAsFixed(0)}m²',
      layout: listing.layout,
      decoration: listing.decoration,
      district: listing.district,
      listingId: listing.id,
      verificationStatus: listing.verificationStatus,
    );

    return Dismissible(
      key: Key(listing.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HousingService.removeFromHistory(listing.id);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () {
          HousingService.recordBrowse(listing.id);
          Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => HousingDetailPage(house: house)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 80, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(CupertinoIcons.house_fill, size: 24, color: CupertinoColors.systemGrey3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(listing.district, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                        const SizedBox(width: 8),
                        Text(listing.layout, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                        const SizedBox(width: 8),
                        Text('${listing.size.toStringAsFixed(0)}m²', style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('¥${listing.price.toStringAsFixed(0)}/月', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed)),
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

  void _showClearConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有浏览记录吗？'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () { HousingService.clearHistory(); Navigator.of(ctx).pop(); }, child: const Text('清空')),
        ],
      ),
    );
  }
}
