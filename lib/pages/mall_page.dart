import 'package:flutter/cupertino.dart';
import 'mall_detail_page.dart';
import '../services/verification_service.dart';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class MallProduct {
  final String name;
  final String price;
  final String unit;
  final String emoji;
  final Color bgColor;
  final String tab;
  final String category;
  final String seller;
  final int reputation;
  final String description;

  const MallProduct({
    required this.name,
    required this.price,
    required this.unit,
    required this.emoji,
    required this.bgColor,
    required this.tab,
    required this.category,
    required this.seller,
    required this.reputation,
    required this.description,
  });
}

const List<MallProduct> _allProducts = [
  // ---- 闲置二手 ----
  MallProduct(
    name: '手机壳',
    price: '15',
    unit: '',
    emoji: '\u{1F4F1}',
    bgColor: Color(0xFFE3F2FD),
    tab: '闲置二手',
    category: '数码',
    seller: '小王',
    reputation: 95,
    description: '九成新手机壳，适配iPhone 15 Pro，手感舒适，保护到位。闲置转让，价格实惠。',
  ),
  MallProduct(
    name: '耳机',
    price: '89',
    unit: '',
    emoji: '\u{1F3A7}',
    bgColor: Color(0xFFE8F5E9),
    tab: '闲置二手',
    category: '数码',
    seller: '小李',
    reputation: 98,
    description: '品牌蓝牙耳机，音质出色，续航持久。使用不到半年，因升级设备闲置出售。',
  ),
  MallProduct(
    name: '机械键盘',
    price: '120',
    unit: '',
    emoji: '\u{2328}',
    bgColor: Color(0xFFFFF3E0),
    tab: '闲置二手',
    category: '数码',
    seller: '小张',
    reputation: 92,
    description: '青轴机械键盘，段落感强，码字游戏皆宜。87键紧凑布局，成色良好。',
  ),

  // ---- 农副产品 ----
  MallProduct(
    name: '红富士苹果',
    price: '8',
    unit: '/斤',
    emoji: '\u{1F34E}',
    bgColor: Color(0xFFFFEBEE),
    tab: '农副产品',
    category: '水果',
    seller: '果农老赵',
    reputation: 99,
    description: '自家果园种植的红富士苹果，脆甜多汁，不打蜡不催熟。现摘现发，新鲜直达。',
  ),
  MallProduct(
    name: '东北大米',
    price: '35',
    unit: '/袋',
    emoji: '\u{1F33E}',
    bgColor: Color(0xFFFFFDE7),
    tab: '农副产品',
    category: '粮食',
    seller: '米农老钱',
    reputation: 97,
    description: '东北黑土地种植，颗粒饱满，饭香浓郁。5kg真空包装，品质保证。',
  ),
  MallProduct(
    name: '土蜂蜜',
    price: '68',
    unit: '/瓶',
    emoji: '\u{1F36F}',
    bgColor: Color(0xFFF9FBE7),
    tab: '农副产品',
    category: '特产',
    seller: '蜂农老孙',
    reputation: 96,
    description: '深山土蜂蜜，纯天然零添加。百花酿制，口感醇厚，营养丰富。500g装。',
  ),

  // ---- 工厂直销 ----
  MallProduct(
    name: '家纺四件套',
    price: '89',
    unit: '',
    emoji: '\u{1F6CF}',
    bgColor: Color(0xFFEDE7F6),
    tab: '工厂直销',
    category: '家纺',
    seller: '家纺工厂',
    reputation: 94,
    description: '纯棉四件套，亲肤柔软，不起球不褪色。被套+床单+2枕套，多色可选。',
  ),
  MallProduct(
    name: '保温杯',
    price: '29',
    unit: '',
    emoji: '\u{2615}',
    bgColor: Color(0xFFE0F2F1),
    tab: '工厂直销',
    category: '杯具',
    seller: '杯具工厂',
    reputation: 93,
    description: '316不锈钢保温杯，12小时保温。500ml大容量，防漏设计，适合办公出行。',
  ),
  MallProduct(
    name: '拖鞋',
    price: '15',
    unit: '',
    emoji: '\u{1F45F}',
    bgColor: Color(0xFFFCE4EC),
    tab: '工厂直销',
    category: '鞋履',
    seller: '鞋履工厂',
    reputation: 91,
    description: 'EVA防滑拖鞋，轻便舒适，耐磨耐穿。居家浴室两用，多色多码可选。',
  ),
];

// ---------------------------------------------------------------------------
// Category definitions per tab
// ---------------------------------------------------------------------------

const Map<String, List<String>> _tabCategories = {
  '闲置二手': ['全部', '数码', '家居', '服饰', '图书', '其他'],
  '农副产品': ['全部', '水果', '粮食', '特产', '蔬菜', '肉类'],
  '工厂直销': ['全部', '家纺', '杯具', '鞋履', '日用', '其他'],
};

// ---------------------------------------------------------------------------
// Mall Page
// ---------------------------------------------------------------------------

class MallPage extends StatefulWidget {
  const MallPage({super.key});

  @override
  State<MallPage> createState() => _MallPageState();
}

class _MallPageState extends State<MallPage> {
  final _searchController = TextEditingController();
  String _selectedTab = '闲置二手';
  String _selectedCategory = '全部';

  List<MallProduct> get _filtered {
    var list = _allProducts.where((p) => p.tab == _selectedTab).toList();
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      list = list
          .where((p) => p.name.contains(query) || p.seller.contains(query))
          .toList();
    }
    if (_selectedCategory != '全部') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBuySuccess(BuildContext context, MallProduct product) {
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
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('电波商城'),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          _buildProductGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: '搜索商品或卖家',
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['闲置二手', '农副产品', '工厂直销'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _selectedTab,
        backgroundColor: CupertinoColors.systemGrey5,
        thumbColor: CupertinoColors.white,
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTab = value;
              _selectedCategory = '全部';
            });
          }
        },
        children: Map.fromEntries(
          tabs.map((tab) => MapEntry(
                tab,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    tab,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = _tabCategories[_selectedTab]!;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((cat) {
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey4,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              children: [
                const Icon(CupertinoIcons.cube_box, size: 48, color: CupertinoColors.systemGrey3),
                const SizedBox(height: 12),
                const Text('暂无商品', style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(_filtered[index]),
          childCount: _filtered.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(MallProduct product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => MallDetailPage(product: product)),
      ),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: product.bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              alignment: Alignment.center,
              child: Text(product.emoji, style: const TextStyle(fontSize: 42)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '¥${product.price}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CupertinoColors.destructiveRed),
                        ),
                        if (product.unit.isNotEmpty)
                          Text(product.unit, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(product.seller, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => VerificationService.checkVerification(
                          context,
                          () => _showBuySuccess(context, product),
                          message: '购买商品需要完成实名认证，请先进行认证。',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '购买',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
