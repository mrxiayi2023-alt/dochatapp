import 'package:flutter/cupertino.dart';
import 'housing_page.dart';

class HousingDetailPage extends StatelessWidget {
  final HouseItem house;
  const HousingDetailPage({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(house.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(),
              _buildHeaderInfo(),
              _buildDetailSection(),
              _buildLandlordSection(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final colors = [
      const Color(0xFFE5E5EA),
      const Color(0xFFD1D1D6),
      const Color(0xFFC7C7CC),
    ];
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width - 32,
            margin: EdgeInsets.only(left: index == 0 ? 16 : 0, right: 8),
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.house_fill, size: 48, color: CupertinoColors.systemGrey3),
                const SizedBox(height: 8),
                Text(
                  '${house.title} - 图片${index + 1}',
                  style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(house.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '¥${house.price}/月',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: CupertinoColors.destructiveRed),
          ),
          const SizedBox(height: 4),
          Text(house.decoration, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('房源详情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildDetailRow('区域', house.area),
          _buildDetailRow('户型', house.layout),
          _buildDetailRow('面积', house.size),
          _buildDetailRow('楼层', '8/18层'),
          _buildDetailRow('装修', house.decoration),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('房东信息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemTeal,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('东', style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('张房东', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, size: 14, color: CupertinoColors.systemOrange),
                        const SizedBox(width: 4),
                        const Text('信誉分 98', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('联系房东'),
                      content: Text('即将与${house.title}的房东发起聊天'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('确定'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                color: CupertinoColors.activeBlue,
                pressedOpacity: 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text('联系房东', style: TextStyle(color: CupertinoColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
