import 'package:flutter/cupertino.dart';
import 'dating_profile_page.dart';
import '../services/notification_service.dart';

class DatingUser {
  final String name;
  final int age;
  final double distance;
  final int realnessScore;
  final int interactionScore;
  final int completenessScore;
  final int integrityScore;
  final List<String> tags;
  final String intro;
  final String datingCriteria;
  final Color color;
  final bool isRealNameVerified;
  final bool isFaceVerified;
  final bool isSingleCommitmentSigned;
  final bool isSelf;

  const DatingUser({
    required this.name,
    required this.age,
    required this.distance,
    required this.realnessScore,
    required this.interactionScore,
    required this.completenessScore,
    required this.integrityScore,
    required this.tags,
    required this.intro,
    required this.datingCriteria,
    required this.color,
    required this.isRealNameVerified,
    required this.isFaceVerified,
    required this.isSingleCommitmentSigned,
    this.isSelf = false,
  });

  int get score => realnessScore + interactionScore + completenessScore + integrityScore;
  String get initial => name.characters.first;
}

const _demoUsers = [
  DatingUser(
    name: '张三', age: 28, distance: 3.2,
    realnessScore: 38, interactionScore: 28, completenessScore: 18, integrityScore: 8,
    tags: ['旅行', '摄影', '美食'],
    intro: '热爱生活，喜欢探索世界。希望找到志同道合的你，一起看遍世间美景。',
    datingCriteria: '希望对方善良真诚，热爱旅行和摄影，身高160cm以上。',
    color: CupertinoColors.systemBlue,
    isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: true,
    isSelf: true,
  ),
  DatingUser(
    name: '李四', age: 25, distance: 1.5,
    realnessScore: 36, interactionScore: 26, completenessScore: 16, integrityScore: 10,
    tags: ['健身', '阅读', '音乐'],
    intro: '每天坚持健身，闲暇时喜欢读书听音乐。期待遇见有趣的灵魂。',
    datingCriteria: '希望对方积极向上，热爱运动，能一起分享生活的点滴。',
    color: CupertinoColors.systemGreen,
    isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: false,
  ),
  DatingUser(
    name: '王五', age: 30, distance: 5.8,
    realnessScore: 40, interactionScore: 30, completenessScore: 20, integrityScore: 5,
    tags: ['户外', '登山', '露营'],
    intro: '户外运动爱好者，攀登过十座雪山。希望找到同样热爱自然的你。',
    datingCriteria: '希望对方热爱户外运动，有冒险精神，能一起攀登人生高峰。',
    color: CupertinoColors.systemOrange,
    isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: true,
  ),
  DatingUser(
    name: '赵六', age: 26, distance: 2.1,
    realnessScore: 34, interactionScore: 24, completenessScore: 17, integrityScore: 10,
    tags: ['电影', '美食', '宠物'],
    intro: '有一只可爱的金毛，周末喜欢看电影和探店。期待与你分享快乐。',
    datingCriteria: '希望对方有爱心喜欢小动物，性格温柔，能一起享受生活。',
    color: CupertinoColors.systemPurple,
    isRealNameVerified: true, isFaceVerified: false, isSingleCommitmentSigned: false,
  ),
  DatingUser(
    name: '钱七', age: 29, distance: 4.3,
    realnessScore: 38, interactionScore: 28, completenessScore: 18, integrityScore: 6,
    tags: ['运动', '游泳', '篮球'],
    intro: '运动达人，每周三次健身两次游泳。希望找到一起运动的伙伴。',
    datingCriteria: '希望对方活泼开朗，喜欢运动，能一起挥洒汗水享受健康生活。',
    color: CupertinoColors.systemPink,
    isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: true,
  ),
  DatingUser(
    name: '孙八', age: 27, distance: 6.7,
    realnessScore: 35, interactionScore: 26, completenessScore: 16, integrityScore: 10,
    tags: ['旅行', '画画', '瑜伽'],
    intro: '文艺青年一枚，喜欢画画和瑜伽。旅行是生活中不可或缺的部分。',
    datingCriteria: '希望对方有艺术气息，温柔体贴，能一起感受生活的美好。',
    color: CupertinoColors.systemTeal,
    isRealNameVerified: true, isFaceVerified: false, isSingleCommitmentSigned: true,
  ),
];

class DatingPage extends StatefulWidget {
  const DatingPage({super.key});
  @override
  State<DatingPage> createState() => _DatingPageState();
}

class _DatingPageState extends State<DatingPage> {
  String _selectedGender = '';
  String _selectedAge = '';
  String _selectedDistance = '';

  @override
  void initState() {
    super.initState();
    // 查看交友请求 → 清除婚恋角标
    NotificationService.clearBadge('dating');
  }

  List<DatingUser> get _filtered {
    var list = _demoUsers;
    if (_selectedAge == '20-25') list = list.where((u) => u.age >= 20 && u.age <= 25).toList();
    if (_selectedAge == '25-30') list = list.where((u) => u.age > 25 && u.age <= 30).toList();
    if (_selectedAge == '30+') list = list.where((u) => u.age > 30).toList();
    if (_selectedDistance == '1km内') list = list.where((u) => u.distance <= 1).toList();
    if (_selectedDistance == '3km内') list = list.where((u) => u.distance <= 3).toList();
    if (_selectedDistance == '5km内') list = list.where((u) => u.distance <= 5).toList();
    if (_selectedDistance == '不限') {}
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('电波婚恋'),
          ),
          SliverToBoxAdapter(child: _buildFilterBar()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUserCard(_filtered[index]),
              childCount: _filtered.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final genders = ['', '男', '女'];
    final ages = ['', '20-25', '25-30', '30+'];
    final distances = ['', '1km内', '3km内', '5km内', '不限'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChipGroup('性别', genders, _selectedGender, (v) => setState(() => _selectedGender = v)),
          const SizedBox(width: 8),
          _buildChipGroup('年龄', ages, _selectedAge, (v) => setState(() => _selectedAge = v)),
          const SizedBox(width: 8),
          _buildChipGroup('距离', distances, _selectedDistance, (v) => setState(() => _selectedDistance = v)),
        ],
      ),
    );
  }

  Widget _buildChipGroup(String label, List<String> options, String selected, ValueChanged<String> onSelect) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ),
        const SizedBox(width: 4),
        ...options.where((o) => o.isNotEmpty).map((o) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => onSelect(selected == o ? '' : o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected == o ? CupertinoColors.activeBlue : CupertinoColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == o ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                ),
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontSize: 12,
                  color: selected == o ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildUserCard(DatingUser user) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => DatingProfilePage(user: user)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar area
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: user.color.withValues(alpha: 0.18),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: user.color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.initial,
                      style: const TextStyle(color: CupertinoColors.white, fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('${user.age}岁', style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                          const SizedBox(width: 8),
                          Text('${user.distance}km', style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Score (tappable for detail)
            GestureDetector(
              onTap: () => _showScoreDetail(user),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.star_fill, size: 16, color: CupertinoColors.systemOrange),
                        const SizedBox(width: 4),
                        Text(
                          '恋爱分数 ${user.score}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.info_circle, size: 13, color: CupertinoColors.systemGrey3),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '真实性${user.realnessScore}+互动${user.interactionScore}+完整度${user.completenessScore}+诚信${user.integrityScore}=${user.score}',
                      style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ),
            ),
            // Tags
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: user.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 12, color: user.color, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
            ),
            // Chat button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: () => _sendDatingRequest(user),
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  color: CupertinoColors.activeBlue,
                  pressedOpacity: 0.7,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.chat_bubble_fill, size: 18, color: CupertinoColors.white),
                      SizedBox(width: 6),
                      Text('聊一聊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendDatingRequest(DatingUser user) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('交友请求'),
        content: Text('向${user.name}发送交友请求？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('发送'),
            onPressed: () {
              Navigator.of(ctx).pop();
              showCupertinoDialog(
                context: context,
                builder: (ctx2) => CupertinoAlertDialog(
                  title: const Text('已发送'),
                  content: Text('交友请求已发送，${user.name}同意后可开始聊天'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('好的'),
                      onPressed: () => Navigator.of(ctx2).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showScoreDetail(DatingUser user) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('恋爱分数详情'),
        message: Text('${user.name} 的综合评分明细'),
        actions: [
          _buildScoreItem(ctx, '真实性', user.realnessScore, 40, '身份信息真实度评估'),
          _buildScoreItem(ctx, '互动度', user.interactionScore, 30, '社区互动活跃度评估'),
          _buildScoreItem(ctx, '完整度', user.completenessScore, 20, '个人资料完善度评估'),
          _buildScoreItem(ctx, '诚信度', user.integrityScore, 10, '信用与承诺履行评估'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '综合总分: ${user.score} / 100',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('关闭'),
        ),
      ),
    );
  }

  Widget _buildScoreItem(BuildContext ctx, String label, int score, int max, String desc) {
    final ratio = (score / max).clamp(0.0, 1.0);
    final barColor = ratio >= 0.8
        ? CupertinoColors.systemGreen
        : ratio >= 0.6
            ? CupertinoColors.systemOrange
            : CupertinoColors.systemRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                '$score / $max 分',
                style: TextStyle(color: barColor, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 7,
              width: double.infinity,
              color: CupertinoColors.systemGrey5,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(color: barColor),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(desc, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }
}
