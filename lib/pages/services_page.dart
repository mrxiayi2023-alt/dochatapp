import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class _Service {
  final String emoji;
  final String name;
  final String description;

  const _Service({
    required this.emoji,
    required this.name,
    required this.description,
  });
}

const List<_Service> _services = [
  _Service(emoji: '🔒', name: '担保履约', description: '资金托管，安心交易'),
  _Service(emoji: '🏠', name: '电邮找房', description: '直连房东，无中介费'),
  _Service(emoji: '💕', name: '电邮婚恋', description: '真实交友，恋爱分数'),
  _Service(emoji: '💼', name: '电邮招聘', description: '企业直招，信誉保障'),
  _Service(emoji: '📧', name: '电子邮箱', description: '账号即邮箱，注册即开通'),
  _Service(emoji: '🛒', name: '电邮商城', description: '闲置有价，工农直供'),
];

class _RecentItem {
  final String emoji;
  final String name;
  final String time;

  const _RecentItem({required this.emoji, required this.name, required this.time});
}

const List<_RecentItem> _recentItems = [
  _RecentItem(emoji: '🔒', name: '担保履约', time: '2小时前'),
  _RecentItem(emoji: '📧', name: '电子邮箱', time: '昨天'),
  _RecentItem(emoji: '🛒', name: '电邮商城', time: '刚刚'),
];

// ---------------------------------------------------------------------------
// Services Page
// ---------------------------------------------------------------------------

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('服务'),
          ),
          // --- 五宫格 ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ServiceCard(service: _services[index]),
                childCount: _services.length,
              ),
            ),
          ),
          // --- 最近使用 ---
          SliverToBoxAdapter(
            child: _buildRecentSection(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Recent Section
  // -----------------------------------------------------------------------

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '最近使用',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          ..._recentItems.map((item) => _buildRecentRow(item)),
        ],
      ),
    );
  }

  Widget _buildRecentRow(_RecentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              item.time,
              style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service Card
// ---------------------------------------------------------------------------

class _ServiceCard extends StatelessWidget {
  final _Service service;

  const _ServiceCard({required this.service});

  void _showComingSoon(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('即将上线'),
        content: const Text('该功能正在开发中，敬请期待'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icon
            Text(service.emoji, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            // Service name
            Text(
              service.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              service.description,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // "即将上线" badge (right-aligned)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '即将上线',
                  style: TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}