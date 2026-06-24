// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年6月24日
// 文件说明：实时定位主页面 - 显示开启定位共享的好友列表

import 'package:flutter/cupertino.dart';
import 'location_map_page.dart';
import 'location_geofence_page.dart';

// ---------------------------------------------------------------------------
// Avatar color helpers
// ---------------------------------------------------------------------------

final List<Color> _avatarColors = [
  CupertinoColors.systemBlue,
  CupertinoColors.systemGreen,
  CupertinoColors.systemOrange,
  CupertinoColors.systemPurple,
  CupertinoColors.systemPink,
  CupertinoColors.systemTeal,
  CupertinoColors.systemRed,
  CupertinoColors.systemYellow,
];

Color _nameToColor(String name) {
  return _avatarColors[name.hashCode.abs() % _avatarColors.length];
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

/// 模拟好友定位数据
class _FriendLocation {
  final String userId;
  final String nickname;
  final String distance;
  final String lastUpdate;
  final int battery;
  final bool isOnline;
  final double latitude;
  final double longitude;
  final String direction;

  const _FriendLocation({
    required this.userId,
    required this.nickname,
    required this.distance,
    required this.lastUpdate,
    required this.battery,
    this.isOnline = true,
    this.latitude = 39.9042,
    this.longitude = 116.4074,
    this.direction = '北',
  });
}

final List<_FriendLocation> _mockFriends = [
  _FriendLocation(
    userId: '1',
    nickname: '张三',
    distance: '1.2 km',
    lastUpdate: '刚刚',
    battery: 85,
    latitude: 39.9142,
    longitude: 116.4174,
    direction: '东北',
  ),
  _FriendLocation(
    userId: '2',
    nickname: '李四',
    distance: '3.5 km',
    lastUpdate: '2分钟前',
    battery: 62,
    latitude: 39.8842,
    longitude: 116.4274,
    direction: '南',
  ),
  _FriendLocation(
    userId: '3',
    nickname: '王五',
    distance: '0.8 km',
    lastUpdate: '1分钟前',
    battery: 91,
    latitude: 39.9092,
    longitude: 116.4004,
    direction: '西',
  ),
  _FriendLocation(
    userId: '4',
    nickname: '赵六',
    distance: '5.7 km',
    lastUpdate: '刚刚',
    battery: 73,
    isOnline: false,
    latitude: 39.9542,
    longitude: 116.3574,
    direction: '西北',
  ),
  _FriendLocation(
    userId: '5',
    nickname: '钱七',
    distance: '2.1 km',
    lastUpdate: '5分钟前',
    battery: 48,
    latitude: 39.8942,
    longitude: 116.4374,
    direction: '东南',
  ),
  _FriendLocation(
    userId: '6',
    nickname: '孙八',
    distance: '10.3 km',
    lastUpdate: '刚刚',
    battery: 100,
    latitude: 39.8242,
    longitude: 116.5074,
    direction: '东',
  ),
  _FriendLocation(
    userId: '7',
    nickname: '周九',
    distance: '0.3 km',
    lastUpdate: '30秒前',
    battery: 22,
    isOnline: true,
    latitude: 39.9062,
    longitude: 116.4094,
    direction: '北',
  ),
  _FriendLocation(
    userId: '8',
    nickname: '吴十',
    distance: '6.8 km',
    lastUpdate: '10分钟前',
    battery: 56,
    isOnline: false,
    latitude: 39.8442,
    longitude: 116.4274,
    direction: '西南',
  ),
];

// ---------------------------------------------------------------------------
// Location Sharing Page
// ---------------------------------------------------------------------------

/// 实时定位主页面
class LocationSharingPage extends StatefulWidget {
  const LocationSharingPage({super.key});

  @override
  State<LocationSharingPage> createState() => _LocationSharingPageState();
}

/// LocationSharingPage的状态管理
class _LocationSharingPageState extends State<LocationSharingPage> {
  bool _sharingEnabled = true;
  List<_FriendLocation> _friends = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _friends = List.from(_mockFriends);
  }

  /// 切换定位共享状态
  void _toggleSharing(bool value) {
    if (!value) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('关闭位置共享'),
          content: const Text('关闭后，好友将无法看到您的实时位置。确定要关闭吗？'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _sharingEnabled = false);
                _showNotification();
              },
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _sharingEnabled = true);
    }
  }

  /// 关闭后显示通知提示
  void _showNotification() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('温馨提示'),
        content: const Text('位置共享已关闭。\n您的好友将无法看到您的位置信息。\n如需要时可随时开启。'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 跳转至好友实时位置页面
  void _navigateToMap(_FriendLocation friend) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => LocationMapPage(friendData: {
          'nickname': friend.nickname,
          'latitude': friend.latitude,
          'longitude': friend.longitude,
          'distance': friend.distance,
          'direction': friend.direction,
          'battery': friend.battery,
          'lastUpdate': friend.lastUpdate,
        }),
      ),
    );
  }

  /// 跳转至电子围栏页面
  void _navigateToGeofence() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const LocationGeofencePage()),
    );
  }

  /// 获取搜索过滤后的好友列表
  List<_FriendLocation> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends
        .where((f) => f.nickname.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final subTextColor = isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('实时定位'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToGeofence,
          child: const Icon(CupertinoIcons.location_solid, size: 22),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ---- 我自己的共享开关 ----
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.location,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '我的位置',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          Text(
                            _sharingEnabled ? '位置共享已开启' : '位置共享已关闭',
                            style: TextStyle(
                              fontSize: 13,
                              color: _sharingEnabled
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.destructiveRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _sharingEnabled,
                      activeTrackColor: CupertinoColors.activeBlue,
                      onChanged: _toggleSharing,
                    ),
                  ],
                ),
              ),
            ),
            // ---- 在线人数统计 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    '共享位置的好友',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredFriends.length}人在线',
                    style: TextStyle(
                      fontSize: 13,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            // ---- 搜索框 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSearchTextField(
                placeholder: '搜索好友',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 8),
            // ---- 好友列表 ----
            Expanded(
              child: _filteredFriends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.location_slash,
                            size: 48,
                            color: subTextColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? '未找到匹配的好友' : '暂无好友共享位置',
                            style: TextStyle(color: subTextColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _filteredFriends[index];
                        final isLast = index == _filteredFriends.length - 1;
                        return _buildFriendCard(friend, isLast, cardColor, textColor, subTextColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建好友位置卡片
  Widget _buildFriendCard(
    _FriendLocation friend,
    bool isLast,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final batteryColor = friend.battery > 60
        ? CupertinoColors.systemGreen
        : friend.battery > 20
            ? CupertinoColors.systemOrange
            : CupertinoColors.destructiveRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : BorderRadius.zero,
        boxShadow: [
          if (!isLast)
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : BorderRadius.zero,
        pressedOpacity: 0.5,
        onPressed: () => _navigateToMap(friend),
        child: Row(
          children: [
            // 头像
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _nameToColor(friend.nickname),
                shape: BoxShape.circle,
                border: Border.all(
                  color: friend.isOnline
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey4,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                friend.nickname[0],
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        friend.nickname,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!friend.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '离线',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(CupertinoIcons.location, size: 12, color: CupertinoColors.activeBlue),
                      const SizedBox(width: 2),
                      Text(
                        friend.distance,
                        style: TextStyle(fontSize: 13, color: CupertinoColors.activeBlue),
                      ),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.clock, size: 12, color: subTextColor),
                      const SizedBox(width: 2),
                      Text(
                        friend.lastUpdate,
                        style: TextStyle(fontSize: 13, color: subTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 电量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: batteryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    friend.battery > 80
                        ? CupertinoIcons.battery_100
                        : friend.battery > 50
                            ? CupertinoIcons.battery_100
                            : friend.battery > 20
                                ? CupertinoIcons.battery_25
                                : CupertinoIcons.battery_0,
                    size: 14,
                    color: batteryColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${friend.battery}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: batteryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_right, size: 14, color: subTextColor),
          ],
        ),
      ),
    );
  }
}
