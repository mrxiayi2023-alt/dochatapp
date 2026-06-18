import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Friend Requests Page
// 返回结果：Map 包含 accepted_nickname / accepted_phone（接受时）
// ---------------------------------------------------------------------------

/// 返回结果 key：接受的好友昵称
const String kResultAcceptedNickname = 'accepted_nickname';
/// 返回结果 key：接受的好友手机号
const String kResultAcceptedPhone = 'accepted_phone';
/// 返回结果 key：接受的好友用户ID
const String kResultAcceptedUserId = 'accepted_user_id';

class FriendRequestsPage extends StatefulWidget {
  /// 每次接受/拒绝申请后回调，传递剩余未处理申请数
  final void Function(int remaining)? onCountChanged;
  /// 接受申请后回调，传递被接受者的信息（昵称、手机号、用户ID）
  final void Function(String nickname, String phone, String userId)? onFriendAccepted;

  const FriendRequestsPage({super.key, this.onCountChanged, this.onFriendAccepted});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  /// 本地持久缓存 — 退出页面再进入不丢失
  static final List<Map<String, dynamic>> _allRequests = [];
  static bool _initialized = false;

  bool _loading = true;
  bool _isDemo = false; // 标记当前是否使用 demo 数据

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  // -----------------------------------------------------------------------
  // 数据加载：首次从 API / demo，之后使用本地缓存
  // -----------------------------------------------------------------------

  /// 当前待处理（pending）的申请数
  int get _pendingCount =>
      _allRequests.where((r) => r['status'] == 'pending').length;

  Future<void> _loadRequests() async {
    // 已有缓存则直接使用，不再请求 API
    if (_initialized) {
      setState(() => _loading = false);
      _syncCount();
      return;
    }

    try {
      final data = await ApiService.instance.getFriendRequests();
      if (mounted) {
        // 合并 API 数据到缓存（去重）
        final existingIds = _allRequests.map((r) => r['id']).toSet();
        for (final item in data) {
          final map = Map<String, dynamic>.from(item as Map);
          if (!existingIds.contains(map['id'])) {
            _allRequests.add(map);
          }
        }
        _initialized = true;
        _isDemo = false;
        setState(() => _loading = false);
        _syncCount();
      }
    } catch (_) {
      if (_allRequests.isEmpty) {
        _fallbackToDemo();
      } else {
        _isDemo = true;
        setState(() => _loading = false);
        _syncCount();
      }
    }
  }

  void _syncCount() {
    widget.onCountChanged?.call(_pendingCount);
  }

  void _fallbackToDemo() {
    if (!mounted) return;
    final now = DateTime.now();
    // 仅在缓存为空时填充演示数据
    if (_allRequests.isEmpty) {
      _allRequests.addAll([
        {
          'id': 'demo_1',
          'from_id': 'demo_user_6',
          'from_nickname': '赵六',
          'from_phone': '13800000006',
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'demo_2',
          'from_id': 'demo_user_7',
          'from_nickname': '钱七',
          'from_phone': '13800000007',
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 36)).toIso8601String(),
        },
      ]);
    }
    _initialized = true;
    _isDemo = true;
    setState(() => _loading = false);
    _syncCount();
  }

  // -----------------------------------------------------------------------
  // 接受
  // -----------------------------------------------------------------------

  Future<void> _acceptRequest(String requestId) async {
    // 获取被接受者的信息
    final req = _allRequests.firstWhere(
      (r) => r['id'] == requestId,
      orElse: () => <String, dynamic>{},
    );
    final nickname = req['from_nickname'] as String? ?? '';
    final phone = req['from_phone'] as String? ?? '';
    final userId = req['from_id'] as String? ?? '';

    if (!_isDemo) {
      try {
        await ApiService.instance.acceptFriendRequest(requestId);
      } catch (e) {
        if (mounted) _showToast('接受失败：${e.toString().replaceFirst("Exception: ", "")}');
        return;
      }
    }

    // 更新状态为已接受（不可变更新），不删除记录，不跳转
    if (mounted) {
      setState(() {
        final idx = _allRequests.indexWhere((r) => r['id'] == requestId);
        if (idx != -1) {
          _allRequests[idx] = {
            ..._allRequests[idx],
            'status': 'accepted',
          };
        }
      });
      _syncCount();
      // 通过回调通知上一页添加好友和创建会话
      widget.onFriendAccepted?.call(nickname, phone, userId);
    }
  }

  // -----------------------------------------------------------------------
  // 拒绝
  // -----------------------------------------------------------------------

  Future<void> _rejectRequest(String requestId) async {
    if (!_isDemo) {
      try {
        await ApiService.instance.rejectFriendRequest(requestId);
      } catch (_) {
        // fall through
      }
    }
    // 更新状态为已拒绝（不可变更新），不删除记录
    if (mounted) {
      setState(() {
        final idx = _allRequests.indexWhere((r) => r['id'] == requestId);
        if (idx != -1) {
          _allRequests[idx] = {
            ..._allRequests[idx],
            'status': 'rejected',
          };
        }
      });
      _syncCount();
    }
  }

  // -----------------------------------------------------------------------
  // 左滑删除
  // -----------------------------------------------------------------------

  /// 左滑删除申请（仅本地移除，不调 API）
  Future<void> _deleteRequest(String requestId) async {
    if (mounted) {
      setState(() => _allRequests.removeWhere((r) => r['id'] == requestId));
      _syncCount();
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('好友申请'),
                ),
                if (_allRequests.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        '暂无好友申请',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final req = _allRequests[index];
                        return _RequestItem(
                          nickname: req['from_nickname'] as String? ?? '',
                          phone: req['from_phone'] as String? ?? '',
                          requestId: req['id'] as String? ?? '',
                          createdAt: req['created_at'] as String? ?? '',
                          status: req['status'] as String? ?? 'pending',
                          onAccept: () => _acceptRequest(req['id'] as String),
                          onReject: () => _rejectRequest(req['id'] as String),
                          onDelete: () => _deleteRequest(req['id'] as String),
                          isLast: index == _allRequests.length - 1,
                        );
                      },
                      childCount: _allRequests.length,
                    ),
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request Item
// ---------------------------------------------------------------------------

class _RequestItem extends StatelessWidget {
  final String nickname;
  final String phone;
  final String requestId;
  final String createdAt;
  final String status;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onDelete;
  final bool isLast;

  const _RequestItem({
    required this.nickname,
    required this.phone,
    required this.requestId,
    this.createdAt = '',
    this.status = 'pending',
    required this.onAccept,
    required this.onReject,
    this.onDelete,
    this.isLast = false,
  });

  Color _colorFromName(String name) {
    const colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemRed,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
    ];
    final hash = name.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    return colors[hash.abs() % colors.length];
  }

  /// 格式化相对时间
  String _formatRelativeTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inHours < 48) return '昨天';
      return '${diff.inDays}天前';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = nickname.isNotEmpty ? nickname.characters.first : '?';
    final timeStr = _formatRelativeTime(createdAt);

    return Dismissible(
      key: ValueKey('request_$requestId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: const Text(
          '删除',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        height: 72,
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _colorFromName(nickname),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + time
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (status == 'accepted')
                    // 已接受 — 灰色文字
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(
                        '已接受',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (status == 'rejected')
                    // 已拒绝 — 灰色文字
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(
                        '已拒绝',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else ...[
                    // 待处理 — 蓝色接受按钮 + 灰色拒绝按钮
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      color: CupertinoColors.activeBlue,
                      pressedOpacity: 0.7,
                      onPressed: onAccept,
                      child: const Text(
                        '接受',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      color: CupertinoColors.systemGrey5,
                      pressedOpacity: 0.7,
                      onPressed: onReject,
                      child: const Text(
                        '拒绝',
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isLast)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 72),
                color: CupertinoColors.systemGrey5,
              ),
          ],
        ),
      ),
    );
  }
}
