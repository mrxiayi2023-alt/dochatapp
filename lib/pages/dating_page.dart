import 'package:flutter/cupertino.dart';
import 'dating_profile_page.dart';

class DatingUser {
  final String name;
  final int age;
  final double distance;
  final int score;
  final List<String> tags;
  final String intro;
  final Color color;

  const DatingUser({
    required this.name,
    required this.age,
    required this.distance,
    required this.score,
    required this.tags,
    required this.intro,
    required this.color,
  });

  String get initial => name.characters.first;
}

const _demoUsers = [
  DatingUser(name: '张三', age: 28, distance: 3.2, score: 92, tags: ['旅行', '摄影', '美食'], intro: '热爱生活，喜欢探索世界。希望找到志同道合的你，一起看遍世间美景。', color: CupertinoColors.systemBlue),
  DatingUser(name: '李四', age: 25, distance: 1.5, score: 88, tags: ['健身', '阅读', '音乐'], intro: '每天坚持健身，闲暇时喜欢读书听音乐。期待遇见有趣的灵魂。', color: CupertinoColors.systemGreen),
  DatingUser(name: '王五', age: 30, distance: 5.8, score: 95, tags: ['户外', '登山', '露营'], intro: '户外运动爱好者，攀登过十座雪山。希望找到同样热爱自然的你。', color: CupertinoColors.systemOrange),
  DatingUser(name: '赵六', age: 26, distance: 2.1, score: 85, tags: ['电影', '美食', '宠物'], intro: '有一只可爱的金毛，周末喜欢看电影和探店。期待与你分享快乐。', color: CupertinoColors.systemPurple),
  DatingUser(name: '钱七', age: 29, distance: 4.3, score: 90, tags: ['运动', '游泳', '篮球'], intro: '运动达人，每周三次健身两次游泳。希望找到一起运动的伙伴。', color: CupertinoColors.systemPink),
  DatingUser(name: '孙八', age: 27, distance: 6.7, score: 87, tags: ['旅行', '画画', '瑜伽'], intro: '文艺青年一枚，喜欢画画和瑜伽。旅行是生活中不可或缺的部分。', color: CupertinoColors.systemTeal),
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
            // Score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.star_fill, size: 16, color: CupertinoColors.systemOrange),
                  const SizedBox(width: 4),
                  Text(
                    '恋爱分数 ${user.score}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemOrange),
                  ),
                ],
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
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('聊一聊'),
                        content: Text('即将与${user.name}发起聊天'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('确定'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    );
                  },
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
}
