import 'dart:math';
import 'package:flutter/cupertino.dart';

class HousingListing {
  final String id;
  final String title;
  final String propertyType; // 住宅/商铺/写字楼
  final String district; // 邗江区/广陵区/开发区/江都区/仪征市/高邮市/宝应县/其他
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
    required this.district,
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

  static void _ensureDemo() {
    if (_demoLoaded) return;
    _demoLoaded = true;
    _listings.addAll([
      HousingListing(
        id: 'H001', title: '阳光花园', propertyType: '住宅', district: '邗江区',
        layout: '3室2厅', size: 120, floor: '8/18层', decoration: '简装',
        price: 2500, description: '阳光花园位于邗江区核心地段，交通便利，周边配套齐全，采光好南北通透。',
        contact: '13800001111', publisherType: '个人',
      ),
      HousingListing(
        id: 'H002', title: '翠苑小区', propertyType: '住宅', district: '广陵区',
        layout: '2室1厅', size: 85, floor: '5/11层', decoration: '精装',
        price: 1800, description: '翠苑小区安静宜居，绿化率高，近地铁站，适合上班族。',
        contact: '13800002222', publisherType: '中介', companyName: '安居置业',
      ),
      HousingListing(
        id: 'H003', title: '月亮湾', propertyType: '住宅', district: '邗江区',
        layout: '1室1厅', size: 50, floor: '12/28层', decoration: '精装',
        price: 1200, description: '月亮湾公寓，拎包入住，视野开阔，小区物业管理完善。',
        contact: '13800003333', publisherType: '个人',
      ),
      HousingListing(
        id: 'H004', title: '金色家园', propertyType: '住宅', district: '开发区',
        layout: '4室2厅', size: 150, floor: '3/6层', decoration: '豪装',
        price: 3500, description: '金色家园大平层，南北通透双阳台，豪华装修，带中央空调和地暖。',
        contact: '13800004444', publisherType: '中介', companyName: '贝壳找房',
      ),
      HousingListing(
        id: 'H005', title: '绿洲花苑', propertyType: '住宅', district: '广陵区',
        layout: '3室1厅', size: 100, floor: '7/18层', decoration: '简装',
        price: 2200, description: '绿洲花苑环境优美，紧邻公园，适合家庭居住。',
        contact: '13800005555', publisherType: '个人',
      ),
      HousingListing(
        id: 'H006', title: '星辰公寓', propertyType: '住宅', district: '邗江区',
        layout: '2室2厅', size: 90, floor: '15/22层', decoration: '精装',
        price: 2000, description: '星辰公寓位于邗江区中心，周边商圈繁华，生活便利。',
        contact: '13800006666', publisherType: '中介', companyName: '58同城优选',
      ),
      HousingListing(
        id: 'H007', title: '湖畔新居', propertyType: '住宅', district: '江都区',
        layout: '3室2厅', size: 110, floor: '6/11层', decoration: '精装',
        price: 2800, description: '湖畔新居临湖而建，风景优美，全新装修首次出租。',
        contact: '13900001111', verificationStatus: 'pending', publisherType: '个人',
      ),
      HousingListing(
        id: 'H008', title: '创业大厦', propertyType: '写字楼', district: '开发区',
        layout: '2室1厅', size: 200, floor: '18/32层', decoration: '精装',
        price: 8000, description: '创业大厦甲级写字楼，位于开发区CBD核心，配套完善。',
        contact: '13900002222', verificationStatus: 'pending', publisherType: '中介', companyName: '新城地产',
      ),
    ]);
  }

  static List<HousingListing> get listings {
    _ensureDemo();
    return _listings;
  }

  static void publish(HousingListing listing) {
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

  static void toggleFavorite(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
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
}
