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
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _isDemo = false; // 标记当前是否使用 demo 数据

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  // -----------------------------------------------------------------------
  // 数据加载：先试 API，失败后用 demo
  // -----------------------------------------------------------------------

  Future<void> _loadRequests() async {
    try {
      final data = await ApiService.instance.getFriendRequests();
      if (mounted) {
        setState(() {
          _requests = data.cast<Map<String, dynamic>>();
          _loading = false;
          _isDemo = false;
        });
      }
    } catch (_) {
      _fallbackToDemo();
    }
  }

  void _fallbackToDemo() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _isDemo = true;
      _requests = [
        {'id': 'demo_1', 'from_id': 'demo_user_6', 'from_nickname': '赵六', 'from_phone': '13800000006', 'status': 'pending', 'created_at': '2026-05-28 14:30'},
        {'id': 'demo_2', 'from_id': 'demo_user_7', 'from_nickname': '钱七', 'from_phone': '13800000007', 'status': 'pending', 'created_at': '2026-05-27 09:15'},
      ];
    });
  }

  // -----------------------------------------------------------------------
  // 接受
  // -----------------------------------------------------------------------

  Future<void> _acceptRequest(String requestId) async {
    // 获取被接受者的信息（在移除前缓存）
    final req = _requests.firstWhere(
      (r) => r['id'] == requestId,
      orElse: () => <String, dynamic>{},
    );
    final nickname = req['from_nickname'] as String? ?? '';
    final phone = req['from_phone'] as String? ?? '';
    final userId = req['from_id'] as String? ?? '';

    if (!_isDemo) {
      // 真实数据模式：调用后端 API
      try {
        await ApiService.instance.acceptFriendRequest(requestId);
      } catch (e) {
        // API 失败时仍从本地列表移除，但提示用户
        if (mounted) _showToast('接受失败：${e.toString().replaceFirst("Exception: ", "")}');
        return;
      }
    }

    // 从本地列表移除
    if (mounted) {
      setState(() => _requests.removeWhere((r) => r['id'] == requestId));
      _showToast('已接受好友申请');
      // 将接受结果返回给上一页（包含用户 ID，便于 chat_page 创建新会话）
      Navigator.of(context).pop({
        kResultAcceptedNickname: nickname,
        kResultAcceptedPhone: phone,
        kResultAcceptedUserId: userId,
      });
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
    if (mounted) {
      setState(() => _requests.removeWhere((r) => r['id'] == requestId));
      // 拒绝后不传回特殊结果，但可以刷新角标
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
                if (_requests.isEmpty)
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
                        final req = _requests[index];
                        return _RequestItem(
                          nickname: req['from_nickname'] as String? ?? '',
                          phone: req['from_phone'] as String? ?? '',
                          requestId: req['id'] as String? ?? '',
                          onAccept: () => _acceptRequest(req['id'] as String),
                          onReject: () => _rejectRequest(req['id'] as String),
                          isLast: index == _requests.length - 1,
                        );
                      },
                      childCount: _requests.length,
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
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isLast;

  const _RequestItem({
    required this.nickname,
    required this.phone,
    required this.requestId,
    required this.onAccept,
    required this.onReject,
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

  @override
  Widget build(BuildContext context) {
    final initial = nickname.isNotEmpty ? nickname.characters.first : '?';
    return Container(
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
                // Name + phone
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
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Accept button
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
                // Reject button
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  color: CupertinoColors.systemGrey5,
                  pressedOpacity: 0.7,
                  onPressed: onReject,
                  child: Text(
                    '拒绝',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
    );
  }
}
