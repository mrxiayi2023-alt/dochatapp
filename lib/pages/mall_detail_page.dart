import 'package:flutter/cupertino.dart';
import 'mall_page.dart';

class MallDetailPage extends StatelessWidget {
  final MallProduct product;
  const MallDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageArea(),
                  _buildProductInfo(),
                  _buildSellerInfo(context),
                  _buildDescription(),
                  const SizedBox(height: 100), // space for bottom button
                ],
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 260,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: product.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(product.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          Text(
            '商品图片占位',
            style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
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
          Text(
            product.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${product.price}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: CupertinoColors.destructiveRed,
                ),
              ),
              if (product.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    product.unit,
                    style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '分类: ${product.category}',
            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(BuildContext context) {
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
          const Text('卖家信息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
                child: Text(
                  product.seller.characters.first,
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.seller, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, size: 14, color: CupertinoColors.systemOrange),
                        const SizedBox(width: 4),
                        Text('信誉分 ${product.reputation}', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
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
                      title: const Text('联系卖家'),
                      content: Text('即将与「${product.seller}」发起聊天'),
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
                child: const Text('联系卖家', style: TextStyle(color: CupertinoColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
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
          const Text('商品描述', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: const TextStyle(fontSize: 15, color: CupertinoColors.darkBackgroundGray, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: CupertinoButton(
        onPressed: () {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('购买成功'),
              content: Text('已购买「${product.name}」\n¥${product.price}${product.unit}'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        color: CupertinoColors.activeBlue,
        pressedOpacity: 0.7,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Text(
          '立即购买',
          style: TextStyle(color: CupertinoColors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
