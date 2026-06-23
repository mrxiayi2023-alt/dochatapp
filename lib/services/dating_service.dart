import 'package:flutter/cupertino.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------------
// DatingUser model
// ---------------------------------------------------------------------------

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
  final String? userId; // 后端用户ID

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
    this.userId,
  });

  int get score => realnessScore + interactionScore + completenessScore + integrityScore;
  String get initial => name.characters.first;
}

// ---------------------------------------------------------------------------
// DatingService
// ---------------------------------------------------------------------------

class DatingService {
  DatingService._();

  static final List<DatingUser> _users = [];
  static bool _apiLoaded = false;
  static bool _demoLoaded = false;

  /// 是否已从API加载真实数据
  static bool get isApiLoaded => _apiLoaded;

  // 演示数据（从 dating_page.dart 迁移过来）
  static const List<DatingUser> _demoUsers = [
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

  /// 获取推荐用户列表，API优先，失败回退到演示数据
  static List<DatingUser> get users {
    if (_apiLoaded && _users.isNotEmpty) return List.unmodifiable(_users);
    if (!_demoLoaded) {
      _demoLoaded = true;
      _loadFromApi();
    }
    return List.unmodifiable(_demoUsers);
  }

  /// 后台加载API数据
  static Future<void> _loadFromApi() async {
    try {
      final api = ApiService.instance;
      final items = await api.getDatingRecommend();
      if (items.isNotEmpty) {
        _users.clear();
        for (final item in items) {
          _users.add(DatingUser(
            name: item['name'] as String? ?? '',
            age: item['age'] as int? ?? 0,
            distance: (item['distance'] as num?)?.toDouble() ?? 0,
            realnessScore: item['realness_score'] as int? ?? 0,
            interactionScore: item['interaction_score'] as int? ?? 0,
            completenessScore: item['completeness_score'] as int? ?? 0,
            integrityScore: item['integrity_score'] as int? ?? 0,
            tags: (item['tags'] is List) ? List<String>.from(item['tags']) : [],
            intro: item['intro'] as String? ?? '',
            datingCriteria: item['dating_criteria'] as String? ?? '',
            color: CupertinoColors.systemBlue,
            isRealNameVerified: false,
            isFaceVerified: false,
            isSingleCommitmentSigned: false,
            userId: item['user_id'] as String?,
          ));
        }
        _apiLoaded = true;
      }
    } catch (_) {
      // API 不可用，保持演示数据
    }
  }
}
