import 'package:flutter/cupertino.dart';
import 'escrow_page.dart';
import 'housing_page.dart';
import 'dating_page.dart';
import 'jobs_page.dart';
import 'mail_page.dart';
import 'mall_page.dart';
import 'logistics_page.dart';
import '../services/notification_service.dart';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class _Service {
  final String emoji;
  final String name;
  final String description;
  final String ecosystem; // key for NotificationService badge lookup

  const _Service({
    required this.emoji,
    required this.name,
    required this.description,
    required this.ecosystem,
  });
}

const List<_Service> _services = [
  _Service(emoji: '🔒', name: '电波担保', description: '资金托管，安心交易', ecosystem: 'escrow'),
  _Service(emoji: '🛒', name: '电波商城', description: '闲置有价，工农直供', ecosystem: 'mall'),
  _Service(emoji: '💕', name: '电波婚恋', description: '真实交友，恋爱分数', ecosystem: 'dating'),
  _Service(emoji: '🏠', name: '电波找房', description: '直连房东，无中介费', ecosystem: 'housing'),
  _Service(emoji: '💼', name: '电波直聘', description: '企业直招，信誉保障', ecosystem: 'jobs'),
  _Service(emoji: '📧', name: '电波邮箱', description: '账号即邮箱，注册即开通', ecosystem: 'mail'),
  _Service(emoji: '🚚', name: '电波速运', description: '同城货运，长途物流', ecosystem: 'logistics'),
];

class _RecentItem {
  final String emoji;
  final String name;
  final String time;

  const _RecentItem({required this.emoji, required this.name, required this.time});
}

const List<_RecentItem> _recentItems = [
  _RecentItem(emoji: '🔒', name: '电波担保', time: '2小时前'),
  _RecentItem(emoji: '📧', name: '电波邮箱', time: '昨天'),
  _RecentItem(emoji: '🛒', name: '电波商城', time: '刚刚'),
];

// ---------------------------------------------------------------------------
// Services Page
// ---------------------------------------------------------------------------

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  @override
  void initState() {
    super.initState();
    NotificationService.totalNotifier.addListener(_onBadgeChange);
  }

  @override
  void dispose() {
    NotificationService.totalNotifier.removeListener(_onBadgeChange);
    super.dispose();
  }

  void _onBadgeChange() {
    if (mounted) setState(() {});
  }

  VoidCallback? _onServiceTap(BuildContext context, _Service service) {
    switch (service.name) {
      case '电波担保':
        return () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const EscrowPage()),
            );
      case '电波找房':
        return () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const HousingPage()),
            );
      case '电波婚恋':
        return () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const DatingPage()),
            );
      case '电波直聘':
        return () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const JobsPage()),
            );
      case '电波邮箱':
        return () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const MailPage()),
            );
      case '电波速运':
        return () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const LogisticsPage()),);
      case '电波商城':
        return () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const MallPage()),
            );
      default:
        return null; // falls back to "即将上线" dialog
    }
  }

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
                (context, index) {
                  final service = _services[index];
                  return _ServiceCard(
                    service: service,
                    onTap: _onServiceTap(context, service),
                  );
                },
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
  final VoidCallback? onTap;

  const _ServiceCard({required this.service, this.onTap});

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
    final badge = NotificationService.getBadge(service.ecosystem);
    return GestureDetector(
      onTap: onTap ?? (() => _showComingSoon(context)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
      if (badge > 0)
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: CupertinoColors.destructiveRed,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              badge > 9 ? '9+' : '$badge',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
      ),
    );
  }
}