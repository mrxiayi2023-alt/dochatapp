import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Video feed item data model
// ---------------------------------------------------------------------------

class _VideoItem {
  final String name;
  final String initial;
  final Color avatarColor;
  final List<Color> gradientColors;
  final String description;
  int likes;
  int comments;
  int shares;
  bool isLiked = false;
  bool isFollowing = false;

  _VideoItem({
    required this.name,
    required this.initial,
    required this.avatarColor,
    required this.gradientColors,
    required this.description,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });
}

// ---------------------------------------------------------------------------
// Mock video data
// ---------------------------------------------------------------------------

final List<_VideoItem> _mockVideos = [
  _VideoItem(
    name: '旅行者小张',
    initial: '张',
    avatarColor: CupertinoColors.systemBlue,
    gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    description: '西藏·纳木错 ｜ 天空之镜，美到窒息 🌊',
    likes: 2847,
    comments: 125,
    shares: 340,
  ),
  _VideoItem(
    name: '美食猎人',
    initial: '美',
    avatarColor: CupertinoColors.systemOrange,
    gradientColors: [Color(0xFFf12711), Color(0xFFf5af19)],
    description: '成都苍蝇馆子探店！这碗面绝了 🔥',
    likes: 5632,
    comments: 432,
    shares: 1200,
  ),
  _VideoItem(
    name: '猫咪日常',
    initial: '猫',
    avatarColor: CupertinoColors.systemGreen,
    gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    description: '小橘的午后时光 🐱 治愈系',
    likes: 12893,
    comments: 879,
    shares: 3451,
  ),
  _VideoItem(
    name: '科技达人',
    initial: '科',
    avatarColor: CupertinoColors.systemPurple,
    gradientColors: [Color(0xFF3a1c71), Color(0xFFd76d77)],
    description: '2024年最值得入手的数码好物盘点 📱',
    likes: 3902,
    comments: 315,
    shares: 890,
  ),
  _VideoItem(
    name: '健身教练阿强',
    initial: '强',
    avatarColor: CupertinoColors.systemRed,
    gradientColors: [Color(0xFFe65c00), Color(0xFFF9D423)],
    description: '居家7天练出马甲线🔥跟练版来啦',
    likes: 7541,
    comments: 623,
    shares: 2500,
  ),
  _VideoItem(
    name: '手作达人',
    initial: '手',
    avatarColor: CupertinoColors.systemPink,
    gradientColors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
    description: 'DIY永生花相框｜送闺蜜最佳礼物 🎁',
    likes: 2105,
    comments: 178,
    shares: 560,
  ),
  _VideoItem(
    name: '音乐日记',
    initial: '音',
    avatarColor: CupertinoColors.systemTeal,
    gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    description: '落日飞车 - 我是一只鱼 🎸 现场版',
    likes: 9867,
    comments: 701,
    shares: 2134,
  ),
  _VideoItem(
    name: '穿搭博主小C',
    initial: 'C',
    avatarColor: CupertinoColors.systemIndigo,
    gradientColors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    description: '通勤穿搭｜一周不重样 👗',
    likes: 4567,
    comments: 389,
    shares: 1023,
  ),
];

// ---------------------------------------------------------------------------
// Like animation - floating heart
// ---------------------------------------------------------------------------

class _FloatingHeart extends StatefulWidget {
  final VoidCallback onComplete;

  const _FloatingHeart({
    super.key,
    required this.onComplete,
  });

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0.3, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.elasticOut)),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.decelerate)),
    );
    _offsetAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -200),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _offsetAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: child,
            ),
          ),
        );
      },
      child: const Icon(
        CupertinoIcons.heart_fill,
        size: 120,
        color: CupertinoColors.white,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single video page
// ---------------------------------------------------------------------------

class _SingleVideoPage extends StatefulWidget {
  final _VideoItem item;

  const _SingleVideoPage({required this.item});

  @override
  State<_SingleVideoPage> createState() => _SingleVideoPageState();
}

class _SingleVideoPageState extends State<_SingleVideoPage> {
  int _heartIdCounter = 0;
  final List<_FloatingHeart> _hearts = [];

  void _onDoubleTap() {
    setState(() {
      if (widget.item.isLiked) {
        widget.item.isLiked = false;
        widget.item.likes--;
      } else {
        widget.item.isLiked = true;
        widget.item.likes++;
      }
    });
    _addHeart();
  }

  void _addHeart() {
    final id = _heartIdCounter++;
    setState(() {
      _hearts.add(
        _FloatingHeart(
          key: ValueKey('heart_$id'),
          onComplete: () {
            if (mounted) {
              setState(() {
                _hearts.removeWhere((h) => h.key == ValueKey('heart_$id'));
              });
            }
          },
        ),
      );
    });
  }

  void _toggleLike() {
    setState(() {
      if (widget.item.isLiked) {
        widget.item.isLiked = false;
        widget.item.likes--;
      } else {
        widget.item.isLiked = true;
        widget.item.likes++;
        _addHeart();
      }
    });
  }

  void _showComments(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('评论（${widget.item.comments}）'),
        message: const Text(''),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('回复 ${widget.item.name}');
            },
            child: const Text('写评论...'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '🎬 风景太美了！在哪里呀？',
                style: TextStyle(fontSize: 14, color: CupertinoColors.black),
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '❤️ 已点赞，太棒了！',
                style: TextStyle(fontSize: 14, color: CupertinoColors.black),
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '这个周末就去打卡！',
                style: TextStyle(fontSize: 14, color: CupertinoColors.black),
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('关闭'),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('分享到'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => widget.item.shares++);
              debugPrint('分享到微信');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.chat_bubble_2_fill, size: 20, color: CupertinoColors.systemGreen),
                SizedBox(width: 8),
                Text('微信'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => widget.item.shares++);
              debugPrint('分享到朋友圈');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.person_2_fill, size: 20, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('朋友圈'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => widget.item.shares++);
              debugPrint('复制链接');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_doc_fill, size: 20, color: CupertinoColors.systemGrey),
                SizedBox(width: 8),
                Text('复制链接'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // ---- Video background (simulated gradient) ----
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.play_fill,
                    size: 40,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ),

          // ---- Bottom gradient overlay for readability ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    CupertinoColors.black.withValues(alpha: 0.6),
                    CupertinoColors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ---- Floating hearts overlay ----
          ..._hearts.map((heart) => Positioned.fill(
            child: Center(child: heart),
          )),

          // ---- Right action bar ----
          Positioned(
            right: 12,
            bottom: size.height * 0.25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar + follow
                _buildAvatarWithFollow(item),
                const SizedBox(height: 16),
                // Like button
                _buildIconButton(
                  icon: item.isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  color: item.isLiked
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.white,
                  label: _formatCount(item.likes),
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 16),
                // Comment button
                _buildIconButton(
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  color: CupertinoColors.white,
                  label: _formatCount(item.comments),
                  onTap: () => _showComments(context),
                ),
                const SizedBox(height: 16),
                // Share button
                _buildIconButton(
                  icon: CupertinoIcons.arrowshape_turn_up_right_fill,
                  color: CupertinoColors.white,
                  label: _formatCount(item.shares),
                  onTap: () => _showShareSheet(context),
                ),
              ],
            ),
          ),

          // ---- Bottom info ----
          Positioned(
            left: 16,
            right: 80,
            bottom: MediaQuery.of(context).padding.bottom + 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${item.name}',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ---- Gesture detector for double tap ----
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _onDoubleTap,
              child: Container(color: const Color(0x00000000)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithFollow(_VideoItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          item.isFollowing = !item.isFollowing;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.avatarColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.initial,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Follow indicator
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: item.isFollowing
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.activeBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: CupertinoColors.white,
                width: 2,
              ),
            ),
            child: Icon(
              item.isFollowing
                  ? CupertinoIcons.check_mark
                  : CupertinoIcons.plus,
              size: 12,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

// ---------------------------------------------------------------------------
// VideoFeedPage - Full-screen TikTok-style swipe feed
// ---------------------------------------------------------------------------

class VideoFeedPage extends StatefulWidget {
  final int initialIndex;

  const VideoFeedPage({super.key, this.initialIndex = 0});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _mockVideos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          // ---- PageView for vertical swipe ----
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _mockVideos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return _SingleVideoPage(item: _mockVideos[index]);
            },
          ),

          // ---- Top bar with page indicator and back button ----
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Row(
              children: [
                // Back button
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  pressedOpacity: 0.6,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${_mockVideos.length}',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
