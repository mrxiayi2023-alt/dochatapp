// 电波灵动即时通讯系统 V1.0
// 开发完成日期：2026年6月24日
// 文件说明：婚恋数据模型与服务（V2）

import 'package:flutter/cupertino.dart';
import 'api_service.dart';

const List<String> kDatingInterests = ['运动','音乐','电影','阅读','旅行','美食','摄影','游戏','宠物','手工'];
const List<String> kEducationLevels = ['不限','高中','大专','本科','硕士','博士'];
const List<String> kIncomeLevels = ['不限','5K以下','5-10K','10-20K','20-50K','50K以上'];
const List<String> kMaritalStatuses = ['不限','未婚','离异','丧偶'];
const List<String> kLoveQuestions = ['你理想的约会方式是什么？','你认为感情中最重要的是什么？','你如何看待异地恋？','你计划在几年内结婚？','你接受和对方父母一起住吗？','你的恋爱中最大的缺点是什么？','你认为吵架后应该谁先低头？','你希望对方有什么样的兴趣爱好？'];

class LoveQA {
  final String question;
  final String answer;
  const LoveQA({required this.question, required this.answer});
  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
  factory LoveQA.fromJson(Map<String, dynamic> j) =>
      LoveQA(question: j['question'] as String? ?? '', answer: j['answer'] as String? ?? '');
}

class DatingUser {
  final String userId;
  final String name;
  final int age;
  final String gender;
  final int height;
  final String education;
  final String occupation;
  final String income;
  final String birthplace;
  final String currentLocation;
  final String maritalStatus;
  final List<String> photos;
  final bool hasVideo;
  final bool hasVoiceIntro;
  final List<String> tags;
  final List<String> interests;
  final String intro;
  final int criteriaAgeMin;
  final int criteriaAgeMax;
  final int criteriaHeightMin;
  final int criteriaHeightMax;
  final String criteriaEducation;
  final String criteriaIncome;
  final String criteriaLocation;
  final List<LoveQA> loveQA;
  final bool isRealNameVerified;
  final bool isFaceVerified;
  final bool isSingleCommitmentSigned;
  final int realnessScore;
  final int interactionScore;
  final int completenessScore;
  final int integrityScore;
  final double distance;
  final bool isOnline;
  final String lastActive;
  final bool isSelf;
  final bool isLiked;
  final bool isSuperLiked;
  final bool isMutualMatch;
  final bool isFavorite;

  int get score => realnessScore + interactionScore + completenessScore + integrityScore;
  String get initial => name.characters.first;
  Color get color {
    const cs = [
      CupertinoColors.systemBlue, CupertinoColors.systemGreen, CupertinoColors.systemOrange,
      CupertinoColors.systemPurple, CupertinoColors.systemPink, CupertinoColors.systemRed,
      CupertinoColors.systemTeal, CupertinoColors.systemIndigo,
    ];
    return cs[userId.hashCode.abs() % cs.length];
  }

  const DatingUser({
    required this.userId, required this.name, required this.age,
    this.gender = '', this.height = 0, this.education = '', this.occupation = '',
    this.income = '', this.birthplace = '', this.currentLocation = '', this.maritalStatus = '',
    this.photos = const [], this.hasVideo = false, this.hasVoiceIntro = false,
    this.tags = const [], this.interests = const [], this.intro = '',
    this.criteriaAgeMin = 0, this.criteriaAgeMax = 0, this.criteriaHeightMin = 0, this.criteriaHeightMax = 0,
    this.criteriaEducation = '', this.criteriaIncome = '', this.criteriaLocation = '',
    this.loveQA = const [],
    this.isRealNameVerified = false, this.isFaceVerified = false, this.isSingleCommitmentSigned = false,
    this.realnessScore = 0, this.interactionScore = 0, this.completenessScore = 0, this.integrityScore = 0,
    this.distance = 0, this.isOnline = false, this.lastActive = '',
    this.isSelf = false, this.isLiked = false, this.isSuperLiked = false,
    this.isMutualMatch = false, this.isFavorite = false,
  });

  DatingUser copyWith({
    String? userId, String? name, int? age, String? gender, int? height,
    String? education, String? occupation, String? income, String? birthplace,
    String? currentLocation, String? maritalStatus,
    List<String>? photos, bool? hasVideo, bool? hasVoiceIntro,
    List<String>? tags, List<String>? interests, String? intro,
    int? criteriaAgeMin, int? criteriaAgeMax, int? criteriaHeightMin, int? criteriaHeightMax,
    String? criteriaEducation, String? criteriaIncome, String? criteriaLocation,
    List<LoveQA>? loveQA,
    bool? isRealNameVerified, bool? isFaceVerified, bool? isSingleCommitmentSigned,
    int? realnessScore, int? interactionScore, int? completenessScore, int? integrityScore,
    double? distance, bool? isOnline, String? lastActive,
    bool? isSelf, bool? isLiked, bool? isSuperLiked, bool? isMutualMatch, bool? isFavorite,
  }) {
    return DatingUser(
      userId: userId ?? this.userId, name: name ?? this.name, age: age ?? this.age,
      gender: gender ?? this.gender, height: height ?? this.height,
      education: education ?? this.education, occupation: occupation ?? this.occupation,
      income: income ?? this.income, birthplace: birthplace ?? this.birthplace,
      currentLocation: currentLocation ?? this.currentLocation,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      photos: photos ?? this.photos, hasVideo: hasVideo ?? this.hasVideo,
      hasVoiceIntro: hasVoiceIntro ?? this.hasVoiceIntro,
      tags: tags ?? this.tags, interests: interests ?? this.interests, intro: intro ?? this.intro,
      criteriaAgeMin: criteriaAgeMin ?? this.criteriaAgeMin,
      criteriaAgeMax: criteriaAgeMax ?? this.criteriaAgeMax,
      criteriaHeightMin: criteriaHeightMin ?? this.criteriaHeightMin,
      criteriaHeightMax: criteriaHeightMax ?? this.criteriaHeightMax,
      criteriaEducation: criteriaEducation ?? this.criteriaEducation,
      criteriaIncome: criteriaIncome ?? this.criteriaIncome,
      criteriaLocation: criteriaLocation ?? this.criteriaLocation,
      loveQA: loveQA ?? this.loveQA,
      isRealNameVerified: isRealNameVerified ?? this.isRealNameVerified,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      isSingleCommitmentSigned: isSingleCommitmentSigned ?? this.isSingleCommitmentSigned,
      realnessScore: realnessScore ?? this.realnessScore,
      interactionScore: interactionScore ?? this.interactionScore,
      completenessScore: completenessScore ?? this.completenessScore,
      integrityScore: integrityScore ?? this.integrityScore,
      distance: distance ?? this.distance, isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive, isSelf: isSelf ?? this.isSelf,
      isLiked: isLiked ?? this.isLiked, isSuperLiked: isSuperLiked ?? this.isSuperLiked,
      isMutualMatch: isMutualMatch ?? this.isMutualMatch,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class DatingFilter {
  String gender;
  int ageMin;
  int ageMax;
  double maxDistance;
  String education;
  int heightMin;
  int heightMax;
  String income;
  String maritalStatus;

  DatingFilter({
    this.gender = '',
    this.ageMin = 18,
    this.ageMax = 60,
    this.maxDistance = 0,
    this.education = '',
    this.heightMin = 0,
    this.heightMax = 0,
    this.income = '',
    this.maritalStatus = '',
  });

  DatingFilter copy() => DatingFilter(
    gender: gender,
    ageMin: ageMin,
    ageMax: ageMax,
    maxDistance: maxDistance,
    education: education,
    heightMin: heightMin,
    heightMax: heightMax,
    income: income,
    maritalStatus: maritalStatus,
  );
}

class DatingService {
  DatingService._();

  static final List<DatingUser> _allUsers = [];
  static final List<DatingUser> _likesWhoLikeMe = [];
  static final List<DatingUser> _visitors = [];
  static final List<DatingUser> _matches = [];
  static final List<DatingUser> _favorites = [];
  static int _superLikesRemaining = 3;
  static bool _apiLoaded = false;
  static bool _demoLoaded = false;

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> likesNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> matchNotifier = ValueNotifier<int>(0);

  static bool get isApiLoaded => _apiLoaded;
  static int get superLikesRemaining => _superLikesRemaining;
  static List<DatingUser> get users => List.unmodifiable(_allUsers);
  static List<DatingUser> get likes => List.unmodifiable(_likesWhoLikeMe);
  static List<DatingUser> get visitors => List.unmodifiable(_visitors);
  static List<DatingUser> get matches => List.unmodifiable(_matches);
  static List<DatingUser> get favorites => List.unmodifiable(_favorites);

  static void initDemo() {
    if (_demoLoaded) return;
    _demoLoaded = true;
    _allUsers.clear();
    _allUsers.addAll(_demoUsers);
    _loadFromApi();
  }

  static Future<void> _loadFromApi() async {
    try {
      final items = await ApiService.instance.getDatingRecommend();
      if (items.isNotEmpty) {
        _allUsers.clear();
        for (final i in items) {
          _allUsers.add(_parseUser(i));
        }
        _apiLoaded = true;
        changeNotifier.value = DateTime.now().millisecondsSinceEpoch;
      }
    } catch (_) {}
  }

  static DatingUser _parseUser(Map<String, dynamic> j) {
    return DatingUser(
      userId: j['user_id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      age: j['age'] as int? ?? 0,
      gender: j['gender'] as String? ?? '',
      height: j['height'] as int? ?? 0,
      education: j['education'] as String? ?? '',
      occupation: j['occupation'] as String? ?? '',
      income: j['income'] as String? ?? '',
      birthplace: j['birthplace'] as String? ?? '',
      currentLocation: j['current_location'] as String? ?? '',
      maritalStatus: j['marital_status'] as String? ?? '',
      photos: (j['photos'] is List) ? List<String>.from(j['photos']) : [],
      hasVideo: j['has_video'] as bool? ?? false,
      hasVoiceIntro: j['has_voice_intro'] as bool? ?? false,
      tags: (j['tags'] is List) ? List<String>.from(j['tags']) : [],
      interests: (j['interests'] is List) ? List<String>.from(j['interests']) : [],
      intro: j['intro'] as String? ?? '',
      criteriaAgeMin: j['criteria_age_min'] as int? ?? 0,
      criteriaAgeMax: j['criteria_age_max'] as int? ?? 0,
      criteriaHeightMin: j['criteria_height_min'] as int? ?? 0,
      criteriaHeightMax: j['criteria_height_max'] as int? ?? 0,
      criteriaEducation: j['criteria_education'] as String? ?? '',
      criteriaIncome: j['criteria_income'] as String? ?? '',
      criteriaLocation: j['criteria_location'] as String? ?? '',
      loveQA: (j['love_qa'] is List)
          ? (j['love_qa'] as List).map((e) => LoveQA.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      isRealNameVerified: j['is_real_name_verified'] as bool? ?? false,
      isFaceVerified: j['is_face_verified'] as bool? ?? false,
      isSingleCommitmentSigned: j['is_single_commitment_signed'] as bool? ?? false,
      realnessScore: j['realness_score'] as int? ?? 0,
      interactionScore: j['interaction_score'] as int? ?? 0,
      completenessScore: j['completeness_score'] as int? ?? 0,
      integrityScore: j['integrity_score'] as int? ?? 0,
      distance: (j['distance'] as num?)?.toDouble() ?? 0,
      isOnline: j['is_online'] as bool? ?? false,
      lastActive: j['last_active'] as String? ?? '',
      isSelf: j['is_self'] as bool? ?? false,
      isLiked: j['is_liked'] as bool? ?? false,
      isSuperLiked: j['is_super_liked'] as bool? ?? false,
      isMutualMatch: j['is_mutual_match'] as bool? ?? false,
      isFavorite: j['is_favorite'] as bool? ?? false,
    );
  }

  static Future<bool> like(String userId, {bool superLike = false}) async {
    if (superLike && _superLikesRemaining <= 0) return false;
    if (superLike) _superLikesRemaining--;

    final user = _allUsers.where((e) => e.userId == userId).firstOrNull;
    if (user != null) {
      final idx = _allUsers.indexWhere((e) => e.userId == userId);
      if (idx >= 0) _allUsers[idx] = user.copyWith(isLiked: true, isSuperLiked: superLike);
      if (!_likesWhoLikeMe.any((e) => e.userId == userId)) {
        _likesWhoLikeMe.add(user.copyWith(isLiked: true, isSuperLiked: superLike));
      }
      if (!_matches.any((e) => e.userId == userId)) {
        _matches.add(user);
        matchNotifier.value = DateTime.now().millisecondsSinceEpoch;
      }
    }

    try {
      await ApiService.instance.likeDatingUser(userId, liked: true);
    } catch (_) {}
    likesNotifier.value = DateTime.now().millisecondsSinceEpoch;
    changeNotifier.value = DateTime.now().millisecondsSinceEpoch;
    return true;
  }

  static void skip(String userId) {
    _allUsers.removeWhere((e) => e.userId == userId);
    changeNotifier.value = DateTime.now().millisecondsSinceEpoch;
  }

  static Future<void> toggleFavorite(String userId) async {
    final idx = _allUsers.indexWhere((e) => e.userId == userId);
    if (idx >= 0) {
      final user = _allUsers[idx];
      _allUsers[idx] = user.copyWith(isFavorite: !user.isFavorite);
      if (_allUsers[idx].isFavorite) {
        if (!_favorites.any((f) => f.userId == userId)) {
          _favorites.add(_allUsers[idx]);
        }
      } else {
        _favorites.removeWhere((e) => e.userId == userId);
      }
    }
    try { } catch (_) {}
    changeNotifier.value = DateTime.now().millisecondsSinceEpoch;
  }

  static List<DatingUser> filter(DatingFilter f) {
    var list = _allUsers.where((u) => !u.isSelf).toList();
    if (f.gender.isNotEmpty) list = list.where((u) => u.gender == f.gender).toList();
    if (f.ageMin > 0) list = list.where((u) => u.age >= f.ageMin).toList();
    if (f.ageMax > 0 && f.ageMax >= f.ageMin) list = list.where((u) => u.age <= f.ageMax).toList();
    if (f.maxDistance > 0) list = list.where((u) => u.distance <= f.maxDistance && u.distance > 0).toList();
    if (f.education.isNotEmpty) list = list.where((u) => u.education == f.education).toList();
    if (f.heightMin > 0) list = list.where((u) => u.height >= f.heightMin).toList();
    if (f.heightMax > 0 && f.heightMax >= f.heightMin) list = list.where((u) => u.height <= f.heightMax).toList();
    if (f.income.isNotEmpty) list = list.where((u) => u.income == f.income).toList();
    if (f.maritalStatus.isNotEmpty) list = list.where((u) => u.maritalStatus == f.maritalStatus).toList();
    return list;
  }

  static List<DatingUser> getNearby(String loc, {double radius = 5}) {
    return _allUsers.where((u) => u.distance <= radius && u.distance > 0 && !u.isSelf).toList();
  }

  static void addVisitor(String userId) {
    final u = _allUsers.where((e) => e.userId == userId).firstOrNull;
    if (u != null && !_visitors.any((v) => v.userId == userId)) {
      _visitors.add(u);
    }
  }

  static final List<DatingUser> _demoUsers = [
    DatingUser(
      userId: 'demo_self', name: '张三', age: 28, gender: '男', height: 178,
      education: '本科', occupation: '软件工程师', income: '20-50K',
      birthplace: '江苏南京', currentLocation: '上海浦东', maritalStatus: '未婚',
      tags: ['旅行', '摄影', '美食'], interests: ['摄影', '旅行', '美食', '音乐'],
      intro: '热爱生活，喜欢探索世界。希望能找到志同道合的你，一起看遍世间美景。',
      criteriaAgeMin: 22, criteriaAgeMax: 32, criteriaHeightMin: 158, criteriaHeightMax: 175,
      criteriaEducation: '本科', criteriaLocation: '上海',
      loveQA: [
        LoveQA(question: '你理想的约会方式是什么？', answer: '一起去看画展或摄影展，然后找一家安静的咖啡馆聊一下午。'),
        LoveQA(question: '你认为感情中最重要的是什么？', answer: '真诚和信任。没有信任的感情就像没有地基的房子。'),
      ],
      isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: true,
      realnessScore: 38, interactionScore: 28, completenessScore: 18, integrityScore: 8,
      distance: 3.2, isOnline: true, lastActive: '刚刚', isSelf: true,
    ),
    DatingUser(
      userId: 'demo_1', name: '李四', age: 25, gender: '女', height: 165,
      education: '硕士', occupation: '医生', income: '20-50K',
      birthplace: '浙江杭州', currentLocation: '上海静安', maritalStatus: '未婚',
      tags: ['健身', '阅读', '音乐'], interests: ['运动', '阅读', '音乐', '电影'],
      intro: '每天坚持健身，闲暇时喜欢读书听音乐。期待遇见有趣的灵魂。',
      criteriaAgeMin: 25, criteriaAgeMax: 35, criteriaHeightMin: 170, criteriaHeightMax: 190,
      criteriaEducation: '本科', criteriaLocation: '上海',
      loveQA: [
        LoveQA(question: '你如何看待异地恋？', answer: '短期可以接受，但不希望长期异地。'),
        LoveQA(question: '你计划在几年内结婚？', answer: '1-2年内遇到合适的人就可以考虑。'),
      ],
      isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: false,
      realnessScore: 36, interactionScore: 26, completenessScore: 16, integrityScore: 10,
      distance: 1.5, isOnline: false, lastActive: '2小时前',
    ),
    DatingUser(
      userId: 'demo_2', name: '王五', age: 30, gender: '男', height: 182,
      education: '本科', occupation: '创业合伙人', income: '50K以上',
      birthplace: '北京海淀', currentLocation: '北京朝阳', maritalStatus: '未婚',
      tags: ['户外', '登山', '露营'], interests: ['旅行', '摄影', '运动'],
      intro: '户外运动爱好者，攀登过十座雪山。希望能找到同样热爱自然的你。',
      criteriaAgeMin: 22, criteriaAgeMax: 30, criteriaHeightMin: 160, criteriaHeightMax: 175,
      criteriaLocation: '北京',
      loveQA: [
        LoveQA(question: '你理想的约会方式是什么？', answer: '一起去户外徒步，感受大自然的美好。'),
      ],
      isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: true,
      realnessScore: 40, interactionScore: 30, completenessScore: 20, integrityScore: 5,
      distance: 5.8, isOnline: true, lastActive: '5分钟前',
    ),
    DatingUser(
      userId: 'demo_3', name: '赵六', age: 26, gender: '女', height: 162,
      education: '本科', occupation: '平面设计师', income: '10-20K',
      birthplace: '四川成都', currentLocation: '上海徐汇', maritalStatus: '未婚',
      tags: ['电影', '美食', '宠物'], interests: ['电影', '美食', '宠物', '手工'],
      intro: '有一只可爱的金毛，周末喜欢看电影和探店。期待与你分享快乐。',
      criteriaAgeMin: 24, criteriaAgeMax: 34, criteriaHeightMin: 170, criteriaHeightMax: 185,
      criteriaEducation: '本科', criteriaLocation: '上海',
      loveQA: [
        LoveQA(question: '你接受和对方父母一起住吗？', answer: '希望有自己的独立空间，可以住得近但不能同住。'),
      ],
      isRealNameVerified: true, isFaceVerified: false, isSingleCommitmentSigned: false,
      realnessScore: 34, interactionScore: 24, completenessScore: 17, integrityScore: 10,
      distance: 2.1, isOnline: true, lastActive: '1小时前',
    ),
    DatingUser(
      userId: 'demo_4', name: '钱七', age: 29, gender: '男', height: 176,
      education: '大专', occupation: '健身教练', income: '10-20K',
      birthplace: '广东深圳', currentLocation: '深圳南山', maritalStatus: '未婚',
      tags: ['运动', '游泳', '篮球'], interests: ['运动', '音乐', '美食'],
      intro: '运动达人，每周三次健身两次游泳。希望能找到一起运动的伙伴。',
      criteriaAgeMin: 22, criteriaAgeMax: 30, criteriaHeightMin: 158, criteriaHeightMax: 175,
      criteriaLocation: '深圳',
      loveQA: [
        LoveQA(question: '你认为吵架后应该谁先低头？', answer: '男生应该先让步，但要沟通解决问题。'),
      ],
      isRealNameVerified: true, isFaceVerified: true, isSingleCommitmentSigned: true,
      realnessScore: 38, interactionScore: 28, completenessScore: 18, integrityScore: 6,
      distance: 4.3, isOnline: true, lastActive: '刚刚',
    ),
    DatingUser(
      userId: 'demo_5', name: '孙八', age: 27, gender: '女', height: 168,
      education: '硕士', occupation: '产品经理', income: '20-50K',
      birthplace: '江苏苏州', currentLocation: '上海黄浦', maritalStatus: '未婚',
      tags: ['旅行', '绘画', '瑜伽'], interests: ['旅行', '阅读', '摄影', '美食'],
      intro: '文艺青年一枚，喜欢绘画和瑜伽。旅行是生活中不可或缺的部分。',
      criteriaAgeMin: 26, criteriaAgeMax: 36, criteriaHeightMin: 173, criteriaHeightMax: 188,
      criteriaEducation: '本科', criteriaLocation: '上海',
      loveQA: [
        LoveQA(question: '你的恋爱中最大的缺点是什么？', answer: '有时候会太理性，希望对方能理解。'),
        LoveQA(question: '你希望对方有什么样的兴趣爱好？', answer: '希望对方也喜欢旅行和阅读，有共同话题。'),
      ],
      isRealNameVerified: true, isFaceVerified: false, isSingleCommitmentSigned: true,
      realnessScore: 35, interactionScore: 26, completenessScore: 16, integrityScore: 10,
      distance: 6.7, isOnline: false, lastActive: '昨天',
    ),
  ];
}
