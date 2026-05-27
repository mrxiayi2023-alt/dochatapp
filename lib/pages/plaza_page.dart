import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Feed item data model
// ---------------------------------------------------------------------------

enum _FeedCategory { follow, recommend, local }

class _FeedItem {
  final String name;
  final String initial;
  final Color color;
  final String content;
  final int imageCount;
  final bool isGroup;
  final _FeedCategory category;
  int likes;
  int comments;
  final String time;

  _FeedItem({
    required this.name,
    required this.initial,
    required this.color,
    required this.content,
    this.imageCount = 0,
    this.isGroup = false,
    this.category = _FeedCategory.recommend,
    this.likes = 0,
    this.comments = 0,
    required this.time,
  });
}

// ---------------------------------------------------------------------------
// Hardcoded demo data
// ---------------------------------------------------------------------------

final List<_FeedItem> _feedItems = [
  _FeedItem(
    name: '张三',
    initial: '张',
    color: CupertinoColors.systemBlue,
    content: '今天天气真好，出去走走！',
    imageCount: 1,
    category: _FeedCategory.follow,
    likes: 12,
    comments: 3,
    time: '2小时前',
  ),
  _FeedItem(
    name: '李四',
    initial: '李',
    color: CupertinoColors.systemGreen,
    content: '分享一篇好文章：Flutter开发技巧',
    category: _FeedCategory.follow,
    likes: 8,
    comments: 1,
    time: '3小时前',
  ),
  _FeedItem(
    name: '王五',
    initial: '王',
    color: CupertinoColors.systemOrange,
    content: '【视频】周末Vlog',
    category: _FeedCategory.recommend,
    likes: 25,
    comments: 7,
    time: '5小时前',
  ),
  _FeedItem(
    name: '项目讨论群',
    initial: '项',
    color: CupertinoColors.systemGreen,
    content: '群文件已更新，大家查看',
    isGroup: true,
    category: _FeedCategory.recommend,
    likes: 5,
    comments: 2,
    time: '昨天',
  ),
  _FeedItem(
    name: '赵六',
    initial: '赵',
    color: CupertinoColors.systemPurple,
    content: '杭州西湖，周末打卡！',
    imageCount: 3,
    category: _FeedCategory.local,
    likes: 18,
    comments: 4,
    time: '昨天',
  ),
  _FeedItem(
    name: '钱七',
    initial: '钱',
    color: CupertinoColors.systemPink,
    content: '推荐这家餐厅，味道超赞',
    imageCount: 1,
    category: _FeedCategory.local,
    likes: 10,
    comments: 0,
    time: '2天前',
  ),
];

// ---------------------------------------------------------------------------
// Plaza Page
// ---------------------------------------------------------------------------

class PlazaPage extends StatefulWidget {
  const PlazaPage({super.key});

  @override
  State<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends State<PlazaPage> {
  int _selectedSegment = 0;
  late List<_FeedItem> _items;
  final Set<String> _likedNames = {};

  /// Map raw index from demo data to the display index within filtered list.
  int _globalIndex(int filteredIndex) {
    final filtered = _getFilteredItems();
    if (filteredIndex < 0 || filteredIndex >= filtered.length) return filteredIndex;
    return _items.indexOf(filtered[filteredIndex]);
  }

  List<_FeedItem> _getFilteredItems() {
    switch (_selectedSegment) {
      case 0: // 关注
        return _items.where((e) => e.category == _FeedCategory.follow).toList();
      case 1: // 推荐 — 全部
        return _items;
      case 2: // 同城
        return _items.where((e) => e.category == _FeedCategory.local).toList();
      default:
        return _items;
    }
  }

  @override
  void initState() {
    super.initState();
    _items = _feedItems.map((e) => _FeedItem(
      name: e.name,
      initial: e.initial,
      color: e.color,
      content: e.content,
      imageCount: e.imageCount,
      isGroup: e.isGroup,
      category: e.category,
      likes: e.likes,
      comments: e.comments,
      time: e.time,
    )).toList();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _toggleLike(int filteredIndex) {
    final gi = _globalIndex(filteredIndex);
    final name = _items[gi].name;
    setState(() {
      if (_likedNames.contains(name)) {
        _likedNames.remove(name);
        _items[gi].likes--;
      } else {
        _likedNames.add(name);
        _items[gi].likes++;
      }
    });
  }

  void _showPublishSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('发布动态'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              print('拍摄照片');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 8),
                Text('拍摄照片'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              print('从相册选择');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 20),
                SizedBox(width: 8),
                Text('从相册选择'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              print('发布文字');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_text, size: 20),
                SizedBox(width: 8),
                Text('发布文字'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('广场'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
              ),
              SliverToBoxAdapter(
                child: _buildSegmentedControl(),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = _getFilteredItems();
                    final item = items[index];
                    return _FeedCard(
                      item: item,
                      isLiked: _likedNames.contains(item.name),
                      onLike: () => _toggleLike(index),
                      onTap: () => print('查看动态详情：${item.name} - ${item.content}'),
                    );
                  },
                  childCount: _getFilteredItems().length,
                ),
              ),
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
          // Floating + button
          Positioned(
            right: 20,
            bottom: 20,
            child: CupertinoButton(
              onPressed: _showPublishSheet,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              color: CupertinoColors.activeBlue,
              pressedOpacity: 0.7,
              padding: EdgeInsets.zero,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: CupertinoSegmentedControl<int>(
        padding: const EdgeInsets.all(2),
        groupValue: _selectedSegment,
        selectedColor: CupertinoColors.activeBlue,
        borderColor: CupertinoColors.systemGrey4,
        onValueChanged: (value) {
          setState(() => _selectedSegment = value);
        },
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('关注', style: TextStyle(fontSize: 14)),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('推荐', style: TextStyle(fontSize: 14)),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('同城', style: TextStyle(fontSize: 14)),
          ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed Card
// ---------------------------------------------------------------------------

class _FeedCard extends StatelessWidget {
  final _FeedItem item;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const _FeedCard({
    required this.item,
    required this.isLiked,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + time
            _buildHeader(),
            // Content text
            if (item.content.isNotEmpty)
              _buildContent(),
            // Image grid
            if (item.imageCount > 0)
              _buildImageGrid(),
            // Action buttons
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.initial,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.isGroup) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.person_2_fill,
                        size: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ],
                  ],
                ),
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Text(
        item.content,
        style: const TextStyle(
          fontSize: 15,
          color: CupertinoColors.black,
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImageGrid() {
    final count = item.imageCount;
    if (count <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildGridContent(count),
      ),
    );
  }

  Widget _buildGridContent(int count) {
    final crossAxisCount = count == 1 ? 1 : (count <= 4 ? 2 : 3);
    final spacing = 4.0;
    final rows = (count + crossAxisCount - 1) ~/ crossAxisCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final itemWidth = (availableWidth - totalSpacing) / crossAxisCount;
        final itemHeight = count == 1 ? itemWidth * 9 / 16 : itemWidth;

        return Column(
          children: List.generate(rows, (rowIndex) {
            final itemsInRow = _itemsInRow(rowIndex, count, crossAxisCount);
            final children = <Widget>[];
            for (int col = 0; col < itemsInRow; col++) {
              children.add(
                Container(
                  width: itemWidth,
                  height: itemHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: count == 1
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.photo, size: 32, color: CupertinoColors.systemGrey3),
                            SizedBox(height: 4),
                            Text('图片占位', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                          ],
                        )
                      : const Icon(CupertinoIcons.photo, size: 24, color: CupertinoColors.systemGrey3),
                ),
              );
              if (col < itemsInRow - 1) {
                children.add(SizedBox(width: spacing));
              }
            }
            return Padding(
              padding: rowIndex > 0 ? EdgeInsets.only(top: spacing) : EdgeInsets.zero,
              child: Row(children: children),
            );
          }),
        );
      },
    );
  }

  int _itemsInRow(int rowIndex, int totalItems, int crossAxisCount) {
    final remaining = totalItems - rowIndex * crossAxisCount;
    return remaining >= crossAxisCount ? crossAxisCount : remaining;
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            borderRadius: BorderRadius.circular(20),
            pressedOpacity: 0.5,
            color: CupertinoColors.systemGrey6,
            onPressed: onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  size: 18,
                  color: isLiked ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.likes}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isLiked ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            borderRadius: BorderRadius.circular(20),
            pressedOpacity: 0.5,
            color: CupertinoColors.systemGrey6,
            onPressed: () {
              showCupertinoModalPopup(
                context: context,
                builder: (ctx) => CupertinoActionSheet(
                  title: const Text('评论'),
                  message: const Text('评论功能即将上线'),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () { Navigator.of(ctx).pop(); print('写评论'); },
                      child: const Text('写评论'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () { Navigator.of(ctx).pop(); print('查看所有评论'); },
                      child: const Text('查看所有评论'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('取消'),
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.bubble_left, size: 18, color: CupertinoColors.systemGrey),
                SizedBox(width: 4),
                Text('评论', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            borderRadius: BorderRadius.circular(20),
            pressedOpacity: 0.5,
            color: CupertinoColors.systemGrey6,
            onPressed: () {
              showCupertinoModalPopup(
                context: context,
                builder: (ctx) => CupertinoActionSheet(
                  title: const Text('转发'),
                  message: const Text('转发功能即将上线'),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () { Navigator.of(ctx).pop(); print('转发到聊天'); },
                      child: const Text('转发到聊天'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () { Navigator.of(ctx).pop(); print('转发到广场'); },
                      child: const Text('转发到广场'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('取消'),
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_right, size: 18, color: CupertinoColors.systemGrey),
                SizedBox(width: 4),
                Text('转发', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}