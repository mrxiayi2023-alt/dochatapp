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
  final double distance; // 距离(km)，0表示不显示
  final bool isSelf; // 自己发布的动态
  final String? location; // 位置信息（如"扬州市·智谷科技综合体"）
  final bool hasVideo; // 是否包含视频

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
    this.distance = 0,
    this.isSelf = false,
    this.location,
    this.hasVideo = false,
  });
}

// ---------------------------------------------------------------------------
// Hardcoded demo data
// ---------------------------------------------------------------------------

final List<_FeedItem> _feedItems = [
  // ---- 关注 Tab（2条） ----
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
    distance: 3.2,
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
    distance: 7.8,
  ),
  // ---- 推荐 Tab（全部6条可见，这里放额外的推荐专属） ----
  _FeedItem(
    name: '王五',
    initial: '王',
    color: CupertinoColors.systemOrange,
    content: '【视频】周末Vlog，打卡网红景点',
    category: _FeedCategory.recommend,
    likes: 25,
    comments: 7,
    time: '5小时前',
    distance: 5.1,
  ),
  _FeedItem(
    name: '项目讨论群',
    initial: '项',
    color: CupertinoColors.systemGreen,
    content: '群文件已更新，大家查看最新设计稿',
    isGroup: true,
    category: _FeedCategory.recommend,
    likes: 5,
    comments: 2,
    time: '昨天',
    distance: 0, // 群聊不显示距离
  ),
  _FeedItem(
    name: '赵六',
    initial: '赵',
    color: CupertinoColors.systemPurple,
    content: '杭州西湖断桥残雪，周末打卡！',
    imageCount: 3,
    category: _FeedCategory.recommend,
    likes: 18,
    comments: 4,
    time: '昨天',
    distance: 9.2,
  ),
  _FeedItem(
    name: '钱七',
    initial: '钱',
    color: CupertinoColors.systemPink,
    content: '推荐这家日料餐厅，三文鱼超赞',
    imageCount: 1,
    category: _FeedCategory.recommend,
    likes: 10,
    comments: 0,
    time: '2天前',
    distance: 6.7,
  ),
  // ---- 视频 Feed 项 ----
  _FeedItem(
    name: '摄影大师',
    initial: '摄',
    color: CupertinoColors.systemIndigo,
    content: '#旅拍 ｜ 冰岛极光，一生必去一次！🎬',
    category: _FeedCategory.recommend,
    likes: 3421,
    comments: 256,
    time: '1小时前',
    distance: 0,
    hasVideo: true,
  ),
  _FeedItem(
    name: '舞蹈达人',
    initial: '舞',
    color: CupertinoColors.systemPink,
    content: '【舞蹈】K-pop随机舞蹈挑战🔥',
    category: _FeedCategory.recommend,
    likes: 5678,
    comments: 432,
    time: '3小时前',
    distance: 2.3,
    hasVideo: true,
  ),
  // ---- 视频 Feed 项 2 ----
  _FeedItem(
    name: '美食探店',
    initial: '美',
    color: CupertinoColors.systemOrange,
    content: '🎬【探店】藏在巷子里的深夜食堂，绝了！',
    category: _FeedCategory.recommend,
    likes: 8923,
    comments: 765,
    time: '30分钟前',
    distance: 1.5,
    hasVideo: true,
  ),
  _FeedItem(
    name: '旅行博主',
    initial: '旅',
    color: CupertinoColors.systemTeal,
    content: '#旅行Vlog ｜ 云南大理环洱海攻略🚗',
    category: _FeedCategory.recommend,
    likes: 12340,
    comments: 1024,
    time: '2小时前',
    distance: 0,
    hasVideo: true,
  ),
  _FeedItem(
    name: '萌宠日常',
    initial: '萌',
    color: CupertinoColors.systemYellow,
    content: '🎥 小猫咪第一次洗澡的反应，太可爱了！',
    category: _FeedCategory.recommend,
    likes: 23456,
    comments: 1890,
    time: '5小时前',
    distance: 4.7,
    hasVideo: true,
  ),

  // ---- 同城 Tab（2条，距离较近） ----
  _FeedItem(
    name: '赵六',
    initial: '赵',
    color: CupertinoColors.systemPurple,
    content: '杭州西湖断桥残雪，周末打卡！',
    imageCount: 3,
    category: _FeedCategory.local,
    likes: 18,
    comments: 4,
    time: '昨天',
    distance: 1.2,
  ),
  _FeedItem(
    name: '钱七',
    initial: '钱',
    color: CupertinoColors.systemPink,
    content: '推荐这家日料餐厅，三文鱼超赞',
    imageCount: 1,
    category: _FeedCategory.local,
    likes: 10,
    comments: 0,
    time: '2天前',
    distance: 0.8,
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
  final Set<String> _followingNames = {};

  /// 从原始 demo 数据重新克隆一份列表
  List<_FeedItem> _cloneFromDemo() {
    return _feedItems.map((e) => _FeedItem(
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
      distance: e.distance,
      isSelf: e.isSelf,
      location: e.location,
      hasVideo: e.hasVideo,
    )).toList();
  }

  /// Map raw index from demo data to the display index within filtered list.
  int _globalIndex(int filteredIndex) {
    final filtered = _getFilteredItems();
    if (filteredIndex < 0 || filteredIndex >= filtered.length) return filteredIndex;
    return _items.indexOf(filtered[filteredIndex]);
  }

  List<_FeedItem> _getFilteredItems() {
    switch (_selectedSegment) {
      case 0: // 推荐 — 不显示 local 分类（避免与同城重复）
        return _items.where((e) => e.category != _FeedCategory.local).toList();
      case 1: // 关注 — 仅显示 follow 分类
        return _items.where((e) => e.category == _FeedCategory.follow).toList();
      case 2: // 同城 — 仅显示 local 分类
        return _items.where((e) => e.category == _FeedCategory.local).toList();
      case 3: // 动态 — 仅显示自己发布的内容
        return _items.where((e) => e.isSelf).toList();
      default:
        return _items;
    }
  }

  @override
  void initState() {
    super.initState();
    _items = _cloneFromDemo();
  }

  /// 下拉刷新：重新加载数据（模拟延迟800ms后恢复）
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _items = _cloneFromDemo();
      });
    }
  }

  /// 关注/取消关注
  void _toggleFollow(String name) {
    setState(() {
      if (_followingNames.contains(name)) {
        _followingNames.remove(name);
      } else {
        _followingNames.add(name);
      }
    });
  }

  void _toggleLike(int filteredIndex) {
    final gi = _globalIndex(filteredIndex);
    if (gi < 0 || gi >= _items.length) return;
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

  void _deletePost(int filteredIndex) {
    final gi = _globalIndex(filteredIndex);
    if (gi < 0 || gi >= _items.length) return;
    setState(() => _items.removeAt(gi));
  }

  void _showPublishSheet() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _PublishPostPage(),
      ),
    );
    if (result == null || !mounted) return;

    final content = result['content'] as String? ?? '';
    final imageCount = result['image_count'] as int? ?? 0;
    final visibility = result['visibility'] as int? ?? 0;
    final location = result['location'] as String?;
    final hasVideo = result['has_video'] as bool? ?? false;
    if (content.isEmpty && imageCount == 0 && !hasVideo) return;

    setState(() {
      // 插入到列表顶部；新动态同时出现在「推荐」(category=recommend) 和「动态」(isSelf=true)
      _FeedCategory cat;
      switch (visibility) {
        case 0:
          cat = _FeedCategory.recommend;
          break;
        case 2:
          cat = _FeedCategory.follow; // 仅自己可见暂放入关注tab
          break;
        default:
          cat = _FeedCategory.recommend;
      }
      _items.insert(0, _FeedItem(
        name: '我',
        initial: '我',
        color: CupertinoColors.systemBlue,
        content: content,
        imageCount: imageCount,
        category: cat,
        likes: 0,
        comments: 0,
        time: '刚刚',
        distance: 0,
        isSelf: true,
        location: location,
        hasVideo: hasVideo,
      ));
    });
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
                      key: ValueKey('${_selectedSegment}_${item.name}_$index'),
                      item: item,
                      isLiked: _likedNames.contains(item.name),
                      isFollowing: _followingNames.contains(item.name),
                      onLike: () => _toggleLike(index),
                      onFollow: () => _toggleFollow(item.name),
                      onTap: () { if (item.hasVideo) { showCupertinoDialog(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('视频播放'), content: Text('即将播放：${item.content}'), actions: [CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(context))])); } else { debugPrint('查看动态详情：${item.name} - ${item.content}'); } },
                      onDelete: item.isSelf ? () => _deletePost(index) : null,
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
        children: {
          0: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('推荐', style: TextStyle(fontSize: 13)),
          ),
          1: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('关注', style: TextStyle(fontSize: 13)),
          ),
          2: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('同城', style: TextStyle(fontSize: 13)),
          ),
          3: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text('动态', style: TextStyle(fontSize: 13)),
          ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Follow Button (in-header)
// ---------------------------------------------------------------------------

/// 关注/取消关注按钮
class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: isFollowing
          ? const Text(
              '已关注',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w400,
              ),
            )
          : const Text(
              '+ 关注',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w500,
              ),
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
  final bool isFollowing;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _FeedCard({
    super.key,
    required this.item,
    required this.isLiked,
    required this.isFollowing,
    required this.onLike,
    required this.onFollow,
    required this.onTap,
    this.onDelete,
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
            _buildHeader(context),
            // Content text
            if (item.content.isNotEmpty)
              _buildContent(),
            // Video placeholder
            if (item.hasVideo)
              _buildVideoPlaceholder(),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          // Name + distance + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: 用户名 + 群聊图标 + 关注按钮
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    // 关注按钮（非自己发布的动态才显示）
                    if (!item.isSelf) ...[
                      const SizedBox(width: 8),
                      _FollowButton(
                        isFollowing: isFollowing,
                        onTap: onFollow,
                      ),
                    ],
                  ],
                ),
                // Row 2: 距离 + 时间
                Row(
                  children: [
                    if (item.distance > 0) ...[
                      Text(
                        '${item.distance.toStringAsFixed(1)}km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                // Row 3: 位置（如果有）
                if (item.location != null && item.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid, size: 12, color: CupertinoColors.systemGrey2),
                      const SizedBox(width: 3),
                      Text(
                        item.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // "..." button for self-published posts
          if (item.isSelf && onDelete != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(28, 28),
              pressedOpacity: 0.5,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (ctx) => CupertinoActionSheet(
                    actions: [
                      CupertinoActionSheetAction(
                        isDestructiveAction: true,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onDelete?.call();
                        },
                        child: const Text('删除'),
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
              child: const Icon(
                CupertinoIcons.ellipsis,
                size: 20,
                color: CupertinoColors.systemGrey,
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

  Widget _buildVideoPlaceholder() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: CupertinoColors.systemPurple.withValues(alpha: 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.videocam_fill, size: 36, color: CupertinoColors.systemPurple),
                const SizedBox(height: 6),
                Text(
                  '动态',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemPurple.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                      onPressed: () { Navigator.of(ctx).pop(); debugPrint('写评论'); },
                      child: const Text('写评论'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () { Navigator.of(ctx).pop(); debugPrint('查看所有评论'); },
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
                      onPressed: () { Navigator.of(ctx).pop(); debugPrint('转发到聊天'); },
                      child: const Text('转发到聊天'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () { Navigator.of(ctx).pop(); debugPrint('转发到广场'); },
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

// ---------------------------------------------------------------------------
// Publish Post Page
// ---------------------------------------------------------------------------

class _PublishPostPage extends StatefulWidget {
  const _PublishPostPage();

  @override
  State<_PublishPostPage> createState() => _PublishPostPageState();
}

class _PublishPostPageState extends State<_PublishPostPage> {
  final TextEditingController _textController = TextEditingController();
  final List<Color> _images = []; // 图片占位色块列表
  int _visibility = 0; // 0:公开, 1:好友可见, 2:仅自己可见
  bool _locationEnabled = false;
  bool _isVideoTab = false; // 当前选中"视频"标签
  bool _hasVideo = false; // 是否已添加视频
  // TODO: 接入高德地图SDK获取真实定位，替换此模拟地址
  static const String _simulatedLocation = '扬州市·智谷科技综合体';

  static const List<Color> _palette = [
    CupertinoColors.systemRed,
    CupertinoColors.systemOrange,
    CupertinoColors.systemYellow,
    CupertinoColors.systemGreen,
    CupertinoColors.systemTeal,
    CupertinoColors.systemBlue,
    CupertinoColors.systemPurple,
    CupertinoColors.systemPink,
    CupertinoColors.systemIndigo,
  ];

  static const int _maxImages = 9;

  bool get _canPublish =>
      _textController.text.trim().isNotEmpty || _images.isNotEmpty || _hasVideo;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addImage() {
    if (_images.length >= _maxImages) return;
    setState(() {
      _images.add(_palette[_images.length % _palette.length]);
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _addVideo() {
    // 替换已有视频（只能保留1个）
    setState(() => _hasVideo = true);
  }

  void _removeVideo() {
    setState(() => _hasVideo = false);
  }

  void _publish() {
    if (!_canPublish) return;
    Navigator.of(context).pop({
      'content': _textController.text.trim(),
      'image_count': _images.length,
      'visibility': _visibility,
      if (_locationEnabled) 'location': _simulatedLocation,
      if (_hasVideo) 'has_video': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.5,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 17),
          ),
        ),
        middle: const Text(
          '发布动态',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: _canPublish ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
          pressedOpacity: 0.7,
          onPressed: _canPublish ? _publish : null,
          child: Text(
            '发布',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _canPublish ? CupertinoColors.white : CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---- 文字输入区 ----
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 200),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: CupertinoTextField(
                      controller: _textController,
                      placeholder: '分享你的生活...',
                      placeholderStyle: const TextStyle(
                        color: CupertinoColors.systemGrey3,
                        fontSize: 17,
                      ),
                      style: const TextStyle(fontSize: 17),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const BoxDecoration(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                // ---- 位置 ----
                _buildLocationRow(),
                // ---- 图片/视频选择区 ----
                _buildMediaSection(),
                // ---- 可见范围选择 ----
                _buildVisibilitySection(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Container(
            height: 0.5,
            color: CupertinoColors.systemGrey5,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.4,
            onPressed: () => setState(() => _locationEnabled = !_locationEnabled),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    size: 18,
                    color: _locationEnabled ? CupertinoColors.activeBlue : CupertinoColors.systemGrey2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationEnabled ? _simulatedLocation : '所在位置',
                      style: TextStyle(
                        fontSize: 15,
                        color: _locationEnabled ? CupertinoColors.black : CupertinoColors.systemGrey2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_locationEnabled)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                      pressedOpacity: 0.5,
                      onPressed: () => setState(() => _locationEnabled = false),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 20,
                        color: CupertinoColors.systemGrey3,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: CupertinoColors.systemGrey5,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // ---- 媒体类型切换 ----
          _buildMediaToggle(),
          const SizedBox(height: 8),
          // ---- 各标签内容 ----
          if (_isVideoTab)
            _hasVideo ? _buildVideoCell() : _buildAddVideoPlaceholder()
          else
            _images.isEmpty ? _buildEmptyImagePlaceholder() : _buildImageGrid(),
        ],
      ),
    );
  }

  Widget _buildMediaToggle() {
    return Row(
      children: [
        _buildToggleChip(
          label: '图片',
          icon: CupertinoIcons.photo,
          isActive: !_isVideoTab,
          onTap: () => setState(() => _isVideoTab = false),
        ),
        const SizedBox(width: 8),
        _buildToggleChip(
          label: '视频',
          icon: CupertinoIcons.videocam,
          isActive: _isVideoTab,
          onTap: () => setState(() => _isVideoTab = true),
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? CupertinoColors.activeBlue.withValues(alpha: 0.1) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCell() {
    return GestureDetector(
      onTap: _removeVideo,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemPurple.withValues(alpha: 0.4), width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.videocam_fill, size: 36, color: CupertinoColors.systemPurple),
                  const SizedBox(height: 6),
                  const Text(
                    '视频已添加',
                    style: TextStyle(fontSize: 14, color: CupertinoColors.systemPurple),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点击移除',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.systemPurple.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.destructiveRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 13,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddVideoPlaceholder() {
    return GestureDetector(
      onTap: _addVideo,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.videocam, size: 36, color: CupertinoColors.systemGrey3),
              SizedBox(height: 6),
              Text(
                '添加视频',
                style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return GestureDetector(
      onTap: _addImage,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.photo_on_rectangle, size: 28, color: CupertinoColors.systemGrey3),
            SizedBox(height: 4),
            Text(
              '添加图片',
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final count = _images.length;
    final showAdd = count < _maxImages;
    final totalCells = count + (showAdd ? 1 : 0);
    final colsPerRow = 3;
    final rows = (totalCells + colsPerRow - 1) ~/ colsPerRow;

    return Column(
      children: List.generate(rows, (row) {
        final cells = <Widget>[];
        for (int col = 0; col < colsPerRow; col++) {
          final index = row * colsPerRow + col;
          if (index < count) {
            cells.add(_buildImageCell(index));
          } else if (index == count && showAdd) {
            cells.add(_buildAddCell());
          }
          if (col < colsPerRow - 1 && index + 1 < totalCells) {
            cells.add(const SizedBox(width: 8));
          }
        }
        return Padding(
          padding: row > 0 ? const EdgeInsets.only(top: 8) : EdgeInsets.zero,
          child: Row(children: cells),
        );
      }),
    );
  }

  Widget _buildImageCell(int index) {
    final color = _images[index];
    return Expanded(
      child: GestureDetector(
        onTap: () => _removeImage(index),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 24, color: color.withValues(alpha: 0.6)),
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.destructiveRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 11,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCell() {
    return Expanded(
      child: GestureDetector(
        onTap: _addImage,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 22, color: CupertinoColors.systemGrey3),
                SizedBox(height: 3),
                Text(
                  '添加',
                  style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySection() {
    const labels = ['公开', '好友可见', '仅自己'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.eye, size: 18, color: CupertinoColors.systemGrey),
          const SizedBox(width: 8),
          const Text(
            '可见范围',
            style: TextStyle(fontSize: 15, color: CupertinoColors.black),
          ),
          const Spacer(),
          CupertinoSegmentedControl<int>(
            padding: const EdgeInsets.all(2),
            groupValue: _visibility,
            selectedColor: CupertinoColors.activeBlue,
            borderColor: CupertinoColors.systemGrey4,
            unselectedColor: CupertinoColors.white,
            onValueChanged: (v) => setState(() => _visibility = v),
            children: {
              for (int i = 0; i < labels.length; i++)
                i: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(labels[i], style: const TextStyle(fontSize: 12)),
                ),
            },
          ),
        ],
      ),
    );
  }
}
