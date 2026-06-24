// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年6月24日
// 文件说明：电子围栏页面 - 添加和管理电子围栏

import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Geofence model
// ---------------------------------------------------------------------------

/// 电子围栏数据模型
class _Geofence {
  final String id;
  final String name;
  final double radiusKm;
  final bool isActive;
  final String createdAt;

  const _Geofence({
    required this.id,
    required this.name,
    required this.radiusKm,
    this.isActive = true,
    this.createdAt = '刚刚',
  });

  String get radiusLabel {
    if (radiusKm < 1) {
      return '${(radiusKm * 1000).toInt()} m';
    }
    return '${radiusKm.toStringAsFixed(radiusKm == radiusKm.truncateToDouble() ? 0 : 1)} km';
  }
}

// ---------------------------------------------------------------------------
// Location Geofence Page
// ---------------------------------------------------------------------------

/// 电子围栏页面
class LocationGeofencePage extends StatefulWidget {
  const LocationGeofencePage({super.key});

  @override
  State<LocationGeofencePage> createState() => _LocationGeofencePageState();
}

/// LocationGeofencePage的状态管理
class _LocationGeofencePageState extends State<LocationGeofencePage> {
  final List<_Geofence> _geofences = [];
  int _nextId = 1;

  // 预设围栏数据
  final List<_Geofence> _presetGeofences = const [
    _Geofence(id: 'preset_1', name: '家', radiusKm: 0.5, createdAt: '昨天'),
    _Geofence(id: 'preset_2', name: '公司', radiusKm: 1.0, createdAt: '昨天'),
    _Geofence(id: 'preset_3', name: '学校', radiusKm: 2.0, isActive: false, createdAt: '3天前'),
  ];

  @override
  void initState() {
    super.initState();
    _geofences.addAll(_presetGeofences);
    _nextId = _presetGeofences.length + 1;
  }

  /// 显示添加围栏对话框
  void _showAddGeofenceDialog() {
    final nameCtrl = TextEditingController();
    double selectedRadius = 0.5;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('添加电子围栏'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: nameCtrl,
                placeholder: '围栏名称（如：家、公司）',
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '选择半径',
                  style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                ),
              ),
              const SizedBox(height: 8),
              // 半径选择行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0.5, 1.0, 2.0, 5.0].map((radius) {
                  final isSelected = selectedRadius == radius;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRadius = radius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        radius >= 1 ? '${radius.toInt()} km' : '${(radius * 1000).toInt()} m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
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
                _addGeofence(nameCtrl.text, selectedRadius);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加围栏
  void _addGeofence(String name, double radiusKm) {
    if (name.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('请输入围栏名称'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    // 检查重名
    if (_geofences.any((g) => g.name == name.trim())) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('该名称已存在，请使用其他名称'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _geofences.add(_Geofence(
        id: 'geofence_${_nextId++}',
        name: name.trim(),
        radiusKm: radiusKm,
        createdAt: '刚刚',
      ));
    });
  }

  /// 切换围栏开关状态
  void _toggleGeofence(int index) {
    setState(() {
      final fence = _geofences[index];
      _geofences[index] = _Geofence(
        id: fence.id,
        name: fence.name,
        radiusKm: fence.radiusKm,
        isActive: !fence.isActive,
        createdAt: fence.createdAt,
      );
    });
  }

  /// 删除围栏
  void _deleteGeofence(int index) {
    final fence = _geofences[index];
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除围栏'),
        content: Text('确定要删除「${fence.name}」吗？'),
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
              setState(() => _geofences.removeAt(index));
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 模拟到达提醒
  void _simulateArrival(String fenceName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.bell_solid, size: 20, color: CupertinoColors.activeBlue),
            const SizedBox(width: 8),
            const Text('到达提醒'),
          ],
        ),
        content: Text('您已到达「$fenceName」附近'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
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
        middle: const Text('电子围栏'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddGeofenceDialog,
          child: const Icon(CupertinoIcons.add, size: 24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- 说明文字 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '当好友进入或离开围栏区域时，您将收到通知提醒。',
                style: TextStyle(fontSize: 13, color: subTextColor),
              ),
            ),
            // ---- 统计 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '共 ${_geofences.length} 个围栏',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_geofences.where((g) => g.isActive).length} 个开启',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ---- 围栏列表 ----
            Expanded(
              child: _geofences.isEmpty
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
                            '暂无电子围栏\n点击右上角 + 添加',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: subTextColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _geofences.length + 1, // +1 为添加卡片
                      itemBuilder: (context, index) {
                        if (index == _geofences.length) {
                          return _buildAddCard(cardColor, textColor, subTextColor);
                        }
                        return _buildGeofenceCard(
                          index, isDark, cardColor, textColor, subTextColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建围栏卡片
  Widget _buildGeofenceCard(
    int index,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final fence = _geofences[index];

    // 围栏颜色
    final Color fenceColor;
    if (fence.name.contains('家')) {
      fenceColor = CupertinoColors.systemBlue;
    } else if (fence.name.contains('公司')) {
      fenceColor = CupertinoColors.systemOrange;
    } else if (fence.name.contains('学校')) {
      fenceColor = CupertinoColors.systemPurple;
    } else {
      fenceColor = CupertinoColors.systemGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            // 围栏图标
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fenceColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                fence.isActive
                    ? CupertinoIcons.location_solid
                    : CupertinoIcons.location_slash,
                size: 20,
                color: fence.isActive ? fenceColor : subTextColor,
              ),
            ),
            const SizedBox(width: 12),
            // 围栏信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        fence.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: fenceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fence.radiusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: fenceColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock, size: 12, color: subTextColor),
                      const SizedBox(width: 2),
                      Text(
                        fence.createdAt,
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: fence.isActive
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemGrey3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        fence.isActive ? '监控中' : '已暂停',
                        style: TextStyle(
                          fontSize: 12,
                          color: fence.isActive
                              ? CupertinoColors.systemGreen
                              : subTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 操作按钮
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 开关
                CupertinoSwitch(
                  value: fence.isActive,
                  activeTrackColor: CupertinoColors.activeBlue,
                  onChanged: (_) => _toggleGeofence(index),
                ),
                const SizedBox(height: 4),
                // 模拟到达
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  pressedOpacity: 0.5,
                  onPressed: fence.isActive
                      ? () => _simulateArrival(fence.name)
                      : null,
                  child: Text(
                    '模拟到达',
                    style: TextStyle(
                      fontSize: 11,
                      color: fence.isActive
                          ? CupertinoColors.activeBlue
                          : subTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // 删除
            GestureDetector(
              onTap: () => _deleteGeofence(index),
              child: Icon(
                CupertinoIcons.delete,
                size: 18,
                color: CupertinoColors.destructiveRed.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建添加电子围栏卡片
  Widget _buildAddCard(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (CupertinoTheme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(12),
        pressedOpacity: 0.5,
        onPressed: _showAddGeofenceDialog,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add_circled, size: 20, color: CupertinoColors.activeBlue),
            const SizedBox(width: 8),
            Text(
              '添加电子围栏',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
