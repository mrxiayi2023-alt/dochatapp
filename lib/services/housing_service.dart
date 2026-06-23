import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';

class HousingListing {
  final String id;
  final String title;
  final String propertyType; // 住宅/商铺/写字楼
  final String province; // 江苏省/浙江省/上海市/福建省
  final String district; // 南京市/苏州市/杭州市 等城市
  final String area; // 鼓楼区/工业园区/西湖区 等区/县
  final String town; // 鼓东街道/湖西街道/西湖街道 等镇/街道
  final String layout;
  final double size;
  final String floor;
  final String decoration;
  final double price;
  final String description;
  final String contact;
  String verificationStatus; // verified / pending
  final List<String> photos;
  final String publisherType; // 个人 / 中介
  final String? companyName;

  HousingListing({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.province,
    required this.district,
    required this.area,
    this.town = '',
    required this.layout,
    required this.size,
    required this.floor,
    required this.decoration,
    required this.price,
    required this.description,
    required this.contact,
    this.verificationStatus = 'verified',
    this.photos = const [],
    this.publisherType = '个人',
    this.companyName,
  });
}

class HousingService {
  HousingService._();

  static final List<HousingListing> _listings = [];
  static final Set<String> _favorites = {};
  static final List<String> _browseHistory = [];
  static bool _demoLoaded = false;
  static bool _apiLoaded = false;

  /// 是否已从API加载真实数据
  static bool get isApiLoaded => _apiLoaded;

  static void _ensureDemo() {
    if (_demoLoaded) return;
    _demoLoaded = true;
    _listings.addAll([
      HousingListing(
        id: 'H001', title: '阳光花园', propertyType: '住宅', province: '江苏省', district: '南京市', area: '鼓楼区', town: '鼓东街道',
        layout: '3室2厅', size: 120, floor: '8/18层', decoration: '简装',
        price: 2500, description: '阳光花园位于南京鼓楼区鼓东街道鼓东社区，交通便利，周边配套齐全，采光好南北通透。',
        contact: '13800001111', publisherType: '个人',
      ),
      HousingListing(
        id: 'H002', title: '翠苑小区', propertyType: '住宅', province: '江苏省', district: '苏州市', area: '工业园区', town: '湖西街道',
        layout: '2室1厅', size: 85, floor: '5/11层', decoration: '精装',
        price: 1800, description: '翠苑小区安静宜居，绿化率高，近地铁站，适合上班族。',
        contact: '13800002222', publisherType: '中介', companyName: '安居置业',
      ),
      HousingListing(
        id: 'H003', title: '月亮湾', propertyType: '住宅', province: '江苏省', district: '苏州市', area: '姑苏区', town: '观前街道',
        layout: '1室1厅', size: 50, floor: '12/28层', decoration: '精装',
        price: 1200, description: '月亮湾公寓，拎包入住，视野开阔，小区物业管理完善。',
        contact: '13800003333', publisherType: '个人',
      ),
      HousingListing(
        id: 'H004', title: '金色家园', propertyType: '住宅', province: '江苏省', district: '扬州市', area: '邗江区', town: '邗上街道',
        layout: '4室2厅', size: 150, floor: '3/6层', decoration: '豪装',
        price: 3500, description: '金色家园大平层，南北通透双阳台，豪华装修，带中央空调和地暖。',
        contact: '13800004444', publisherType: '中介', companyName: '贝壳找房',
      ),
      HousingListing(
        id: 'H005', title: '绿洲花苑', propertyType: '住宅', province: '江苏省', district: '南京市', area: '建邺区', town: '莫愁湖街道',
        layout: '3室1厅', size: 100, floor: '7/18层', decoration: '简装',
        price: 2200, description: '绿洲花苑环境优美，紧邻公园，适合家庭居住。',
        contact: '13800005555', publisherType: '个人',
      ),
      HousingListing(
        id: 'H006', title: '星辰公寓', propertyType: '住宅', province: '浙江省', district: '杭州市', area: '西湖区', town: '西湖街道',
        layout: '2室2厅', size: 90, floor: '15/22层', decoration: '精装',
        price: 2000, description: '星辰公寓位于杭州西湖区西湖街道西湖社区，周边商圈繁华，生活便利。',
        contact: '13800006666', publisherType: '中介', companyName: '58同城优选',
      ),
      HousingListing(
        id: 'H007', title: '湖畔新居', propertyType: '住宅', province: '上海市', district: '上海市', area: '浦东新区', town: '陆家嘴街道',
        layout: '3室2厅', size: 110, floor: '6/11层', decoration: '精装',
        price: 2800, description: '湖畔新居位于上海浦东陆家嘴，临湖而建，风景优美，全新装修首次出租。',
        contact: '13900001111', verificationStatus: 'pending', publisherType: '个人',
      ),
      HousingListing(
        id: 'H008', title: '创业大厦', propertyType: '写字楼', province: '福建省', district: '三明市', area: '三元区', town: '城关街道',
        layout: '2室1厅', size: 200, floor: '18/32层', decoration: '精装',
        price: 8000, description: '创业大厦甲级写字楼，位于三明市三元区城关街道，核心商圈，配套完善。',
        contact: '13900002222', verificationStatus: 'pending', publisherType: '中介', companyName: '新城地产',
      ),
    ]);
    // 后台尝试从API加载真实数据
    _loadFromApi();
  }

  static List<HousingListing> get listings {
    _ensureDemo();
    return _listings;
  }

  static Future<void> publish(HousingListing listing) async {
    // 先调API发布
    try {
      final api = ApiService.instance;
      await api.publishHousing({
        'id': listing.id,
        'title': listing.title,
        'property_type': listing.propertyType,
        'province': listing.province,
        'city': listing.district,
        'district': listing.area,
        'town': listing.town,
        'layout': listing.layout,
        'size': listing.size,
        'floor': listing.floor,
        'decoration': listing.decoration,
        'price': listing.price,
        'description': listing.description,
        'contact': listing.contact,
        'verification_status': listing.verificationStatus,
        'photos': listing.photos,
        'publisher_type': listing.publisherType,
        'company_name': listing.companyName ?? '',
      });
    } catch (_) {
      // API失败静默忽略，本地仍然添加
    }
    _listings.insert(0, listing);
    _notify();
  }

  static void approveVerification(String id) {
    final idx = _listings.indexWhere((l) => l.id == id);
    if (idx != -1) {
      _listings[idx].verificationStatus = 'verified';
      _notify();
    }
  }

  // ---- Favorites ----
  static bool isFavorite(String id) => _favorites.contains(id);

  static Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
      // 调API取消收藏
      try {
        await ApiService.instance.removeHousingFavorite(id);
      } catch (_) {}
    } else {
      _favorites.add(id);
      // 调API添加收藏
      try {
        await ApiService.instance.addHousingFavorite(id);
      } catch (_) {}
    }
    _notify();
  }

  static Set<String> get favoriteIds => Set.unmodifiable(_favorites);

  // ---- Browse history ----
  static void recordBrowse(String id) {
    _browseHistory.remove(id);
    _browseHistory.insert(0, id);
    if (_browseHistory.length > 50) {
      _browseHistory.removeLast();
    }
    _notify();
  }

  static List<HousingListing> get browseHistoryList {
    return _browseHistory
        .map((id) => _listings.where((l) => l.id == id).firstOrNull)
        .where((l) => l != null)
        .cast<HousingListing>()
        .toList();
  }

  static void clearHistory() {
    _browseHistory.clear();
    _notify();
  }

  static void removeFromHistory(String id) {
    _browseHistory.remove(id);
    _notify();
  }

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static void _notify() {
    changeNotifier.value = Random().nextInt(100000);
  }

  // -------------------------------------------------------------------------
  // API integration
  // -------------------------------------------------------------------------

  /// 后台尝试从API加载真实数据，成功则替换演示数据
  static Future<void> _loadFromApi() async {
    try {
      final api = ApiService.instance;
      final result = await api.listHousing();
      final items = result['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        // API有数据，替换演示数据
        _listings.clear();
        for (final item in items) {
          _listings.add(_fromApiJson(item as Map<String, dynamic>));
        }
        _apiLoaded = true;
        _notify();
      }
    } catch (_) {
      // API失败，保持演示数据
    }
  }

  /// 将API返回的JSON转换为HousingListing对象
  static HousingListing _fromApiJson(Map<String, dynamic> json) {
    // 处理Photos字段（可能是JSON字符串或列表）
    List<String> photos = [];
    final rawPhotos = json['photos'];
    if (rawPhotos is List) {
      photos = rawPhotos.cast<String>();
    } else if (rawPhotos is String && rawPhotos != '[]') {
      try {
        final parsed = jsonDecode(rawPhotos);
        if (parsed is List) photos = parsed.cast<String>();
      } catch (_) {}
    }

    return HousingListing(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      propertyType: json['property_type'] as String? ?? '',
      province: json['province'] as String? ?? '',
      district: json['city'] as String? ?? '',        // API的city映射到前端的district
      area: json['district'] as String? ?? '',          // API的district映射到前端的area
      town: json['town'] as String? ?? '',
      layout: json['layout'] as String? ?? '',
      size: (json['size'] as num?)?.toDouble() ?? 0,
      floor: json['floor'] as String? ?? '',
      decoration: json['decoration'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      photos: photos,
      publisherType: json['publisher_type'] as String? ?? '个人',
      companyName: json['company_name'] as String?,
    );
  }
}
