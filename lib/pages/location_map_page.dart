// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年6月24日
// 文件说明：好友实时位置页面 - 模拟地图显示好友实时位置

import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Mock track data for 7-day playback
// ---------------------------------------------------------------------------

/// 模拟轨迹点
class _TrackPoint {
  final String time;
  final double latitude;
  final double longitude;
  final String label;

  const _TrackPoint({
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

/// 生成7天模拟轨迹数据
List<List<_TrackPoint>> _generateMockTracks() {
  final baseLat = 39.9042;
  final baseLng = 116.4074;
  final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return days.map((day) {
    final offset = days.indexOf(day) * 0.01;
    return [
      _TrackPoint(time: '$day 08:00', latitude: baseLat + offset, longitude: baseLng + offset, label: '家'),
      _TrackPoint(time: '$day 09:00', latitude: baseLat + offset + 0.02, longitude: baseLng + offset - 0.01, label: '地铁站'),
      _TrackPoint(time: '$day 12:00', latitude: baseLat + offset + 0.05, longitude: baseLng + offset + 0.02, label: '公司'),
      _TrackPoint(time: '$day 14:00', latitude: baseLat + offset + 0.04, longitude: baseLng + offset + 0.03, label: '咖啡厅'),
      _TrackPoint(time: '$day 18:00', latitude: baseLat + offset + 0.06, longitude: baseLng + offset + 0.01, label: '健身房'),
      _TrackPoint(time: '$day 22:00', latitude: baseLat + offset, longitude: baseLng + offset, label: '家'),
    ];
  }).toList();
}

// ---------------------------------------------------------------------------
// Location Map Page
// ---------------------------------------------------------------------------

/// 好友实时位置页面
class LocationMapPage extends StatefulWidget {
  /// 好友数据：nickname, latitude, longitude, distance, direction, battery, lastUpdate
  final Map<String, dynamic> friendData;

  const LocationMapPage({super.key, required this.friendData});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

/// LocationMapPage的状态管理
class _LocationMapPageState extends State<LocationMapPage> {
  bool _showTrack = false;
  int _selectedDay = 0;
  late List<List<_TrackPoint>> _mockTracks;

  @override
  void initState() {
    super.initState();
    _mockTracks = _generateMockTracks();
  }

  String get _nickname => widget.friendData['nickname'] as String? ?? '好友';
  String get _distance => widget.friendData['distance'] as String? ?? '未知';
  String get _direction => widget.friendData['direction'] as String? ?? '北';
  int get _battery => widget.friendData['battery'] as int? ?? 0;
  String get _lastUpdate => widget.friendData['lastUpdate'] as String? ?? '';

  void _toggleTrackPlayback() {
    setState(() => _showTrack = !_showTrack);
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
        middle: Text(_nickname),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleTrackPlayback,
          child: Icon(
            _showTrack ? CupertinoIcons.square_arrow_left : CupertinoIcons.clock,
            size: 22,
            color: _showTrack ? CupertinoColors.activeBlue : null,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ---- 模拟地图区域 ----
            _buildMapArea(isDark, cardColor, subTextColor),
            // ---- 距离与方向信息 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildInfoCard(CupertinoIcons.location, '距离', _distance, CupertinoColors.activeBlue, cardColor, textColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard(CupertinoIcons.compass, '方向', _direction, CupertinoColors.systemGreen, cardColor, textColor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      _battery > 80 ? CupertinoIcons.battery_100 : _battery > 50 ? CupertinoIcons.battery_100 : CupertinoIcons.battery_25,
                      '电量',
                      '$_battery%',
                      _battery > 60 ? CupertinoColors.systemGreen : _battery > 20 ? CupertinoColors.systemOrange : CupertinoColors.destructiveRed,
                      cardColor,
                      textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ---- 轨迹回放操作面板 ----
            if (_showTrack) _buildTrackPanel(cardColor, textColor, subTextColor),
            // ---- 操作按钮 ----
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    color: CupertinoColors.activeBlue,
                    pressedOpacity: 0.7,
                    onPressed: () => setState(() => _showTrack = true),
                    child: const Center(
                      child: Text('查看7天轨迹回放', style: TextStyle(color: CupertinoColors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    borderRadius: BorderRadius.circular(12),
                    pressedOpacity: 0.5,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Center(child: Text('返回列表', style: TextStyle(fontSize: 15))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模拟地图区域
  Widget _buildMapArea(bool isDark, Color cardColor, Color subTextColor) {
    return Container(
      height: 340,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 网格背景
            Positioned.fill(child: CustomPaint(painter: _MapGridPainter(isDark: isDark))),
            // 地标
            _buildLandmark(60, 250, '家', CupertinoColors.systemBlue, isDark),
            _buildLandmark(220, 180, '公司', CupertinoColors.systemOrange, isDark),
            _buildLandmark(90, 170, '地铁站', CupertinoColors.systemGreen, isDark),
            _buildLandmark(250, 270, '商场', CupertinoColors.systemPurple, isDark),
            // 轨迹覆盖层
            if (_showTrack) ..._buildTrackOverlay(isDark),
            // 好友位置标记
            Positioned(left: 140, top: 120, child: _buildFriendMarker()),
            // 底部信息条
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.clock, size: 14, color: subTextColor),
                    const SizedBox(width: 4),
                    Text('更新于 $_lastUpdate', style: TextStyle(fontSize: 12, color: subTextColor)),
                    const Spacer(),
                    const Icon(CupertinoIcons.minus, size: 16, color: CupertinoColors.systemGrey3),
                    const SizedBox(width: 6),
                    const Text('100m', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey3)),
                  ],
                ),
              ),
            ),
            // 轨迹模式提示
            if (_showTrack)
              Positioned(
                top: 12, left: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.clock_solid, size: 16, color: CupertinoColors.white),
                      const SizedBox(width: 6),
                      const Text('轨迹回放模式', style: TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('点击图标退出', style: TextStyle(color: CupertinoColors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard(IconData icon, String label, String value, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (CupertinoTheme.of(context).brightness == Brightness.light)
            BoxShadow(color: CupertinoColors.systemGrey4.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  /// 构建轨迹回放选择面板
  Widget _buildTrackPanel(Color cardColor, Color textColor, Color subTextColor) {
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (CupertinoTheme.of(context).brightness == Brightness.light)
            BoxShadow(color: CupertinoColors.systemGrey4.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择日期查看轨迹', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _mockTracks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedDay == index;
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  borderRadius: BorderRadius.circular(18),
                  color: isSelected ? CupertinoColors.activeBlue : cardColor,
                  pressedOpacity: 0.7,
                  onPressed: () => setState(() => _selectedDay = index),
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? CupertinoColors.white : subTextColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ...(_mockTracks[_selectedDay].map((point) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: CupertinoColors.activeBlue, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(point.time, style: TextStyle(fontSize: 13, color: subTextColor)),
                const Spacer(),
                Text(point.label, style: TextStyle(fontSize: 13, color: textColor)),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  /// 构建地标标记
  Widget _buildLandmark(double left, double top, String name, Color color, bool isDark) {
    return Positioned(
      left: left, top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: CupertinoColors.white, width: 2)),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3A3C) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(name, style: TextStyle(fontSize: 10, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
          ),
        ],
      ),
    );
  }

  /// 构建轨迹覆盖层
  List<Widget> _buildTrackOverlay(bool isDark) {
    final points = _mockTracks[_selectedDay];
    final widgets = <Widget>[];
    for (int i = 0; i < points.length; i++) {
      final x = 100.0 + i * 28.0;
      final y = 200.0 - (i % 3) * 20.0;
      // 连接线
      if (i < points.length - 1) {
        widgets.add(Positioned(
          left: x, top: y,
          child: Container(
            width: 28, height: 2,
            color: CupertinoColors.activeBlue.withValues(alpha: 0.5),
          ),
        ));
      }
      // 轨迹点
      widgets.add(Positioned(
        left: x - 6, top: y - 6,
        child: Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            shape: BoxShape.circle,
            border: Border.all(color: CupertinoColors.white, width: 2),
          ),
          child: i == 0 ? const Icon(CupertinoIcons.house_fill, size: 6, color: CupertinoColors.white) : null,
        ),
      ));
      // 时间标签
      widgets.add(Positioned(
        left: x - 18, top: y + 12,
        child: Text(
          points[i].time.split(' ')[1],
          style: TextStyle(fontSize: 9, color: isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey),
        ),
      ));
    }
    return widgets;
  }

  /// 构建好友位置标记（大头针风格）
  Widget _buildFriendMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            shape: BoxShape.circle,
            border: Border.all(color: CupertinoColors.white, width: 3),
            boxShadow: [
              BoxShadow(color: CupertinoColors.activeBlue.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
            ],
          ),
          alignment: Alignment.center,
          child: Text(_nickname[0], style: const TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 0, height: 0,
          child: CustomPaint(painter: _ArrowPainter(), size: const Size(12, 8)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters
// ---------------------------------------------------------------------------

/// 地图网格绘制器
class _MapGridPainter extends CustomPainter {
  final bool isDark;
  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark
          ? CupertinoColors.systemGrey5.withValues(alpha: 0.2)
          : CupertinoColors.systemGrey3.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);

    final roadPaint = Paint()
      ..color = isDark ? CupertinoColors.systemGrey4.withValues(alpha: 0.15) : CupertinoColors.white.withValues(alpha: 0.6)
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(0, 220), const Offset(320, 220), roadPaint);
    canvas.drawLine(const Offset(150, 0), const Offset(150, 340), roadPaint);

    final subRoadPaint = Paint()
      ..color = isDark ? CupertinoColors.systemGrey4.withValues(alpha: 0.1) : CupertinoColors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(0, 140), const Offset(320, 140), subRoadPaint);
    canvas.drawLine(const Offset(220, 0), const Offset(220, 340), subRoadPaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => oldDelegate.isDark != isDark;
}

/// 箭头绘制器
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CupertinoColors.activeBlue..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
