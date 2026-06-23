import 'package:flutter/cupertino.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class JobItem {
  final String id;
  final String name;
  final String salary;
  final String company;
  final String location;
  final String experience;
  final String education;
  final String description;

  const JobItem({
    required this.id,
    required this.name,
    required this.salary,
    required this.company,
    required this.location,
    required this.experience,
    required this.education,
    required this.description,
  });
}

class CandidateItem {
  final String id;
  final String name;
  final String desiredJob;
  final String desiredSalary;
  final String experience;
  final String education;
  final String skills;

  const CandidateItem({
    required this.id,
    required this.name,
    required this.desiredJob,
    required this.desiredSalary,
    required this.experience,
    required this.education,
    required this.skills,
  });
}

// ---------------------------------------------------------------------------
// Demo data (fallback when API is unavailable)
// ---------------------------------------------------------------------------

const demoJobs = [
  JobItem(id: 'J001', name: '前端开发工程师', salary: '15-25K', company: '智云科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责公司Web前端产品的设计与开发。精通HTML/CSS/JavaScript，熟悉React或Vue框架，有移动端开发经验者优先。'),
  JobItem(id: 'J002', name: 'Java后端开发', salary: '18-30K', company: '星辰软件', location: '扬州市', experience: '5-10年', education: '本科', description: '负责后端服务架构设计与核心模块开发。精通Java/Spring Boot，熟悉微服务架构，有高并发系统开发经验。'),
  JobItem(id: 'J003', name: 'UI设计师', salary: '12-20K', company: '设计工坊', location: '扬州市', experience: '1-3年', education: '大专', description: '负责移动端和Web端产品的UI设计。精通Figma/Sketch，有良好的视觉设计感和用户体验思维。'),
  JobItem(id: 'J004', name: '产品经理', salary: '20-35K', company: '未来科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责产品规划、需求分析与项目管理。具备出色的逻辑思维和沟通能力，有B端产品经验者优先。'),
  JobItem(id: 'J005', name: '测试工程师', salary: '10-18K', company: '云测技术', location: '扬州市', experience: '1-3年', education: '大专', description: '负责软件产品的功能测试和自动化测试。熟悉测试流程和方法论，有自动化测试框架使用经验。'),
  JobItem(id: 'J006', name: '运维工程师', salary: '15-22K', company: '智云科技', location: '扬州市', experience: '3-5年', education: '本科', description: '负责线上服务的运维保障和自动化运维平台建设。熟悉Linux系统，掌握Docker/K8s等容器技术。'),
];

const demoCandidates = [
  CandidateItem(id: 'C001', name: '李明', desiredJob: '前端开发工程师', desiredSalary: '15-25K', experience: '4年', education: '本科', skills: 'React, Vue, Flutter'),
  CandidateItem(id: 'C002', name: '王芳', desiredJob: 'UI设计师', desiredSalary: '12-18K', experience: '3年', education: '本科', skills: 'Figma, Sketch, PS'),
  CandidateItem(id: 'C003', name: '赵强', desiredJob: 'Java后端开发', desiredSalary: '20-30K', experience: '6年', education: '硕士', skills: 'Java, Spring, MySQL'),
  CandidateItem(id: 'C004', name: '张伟', desiredJob: '产品经理', desiredSalary: '18-28K', experience: '4年', education: '本科', skills: 'Axure, 数据分析, SQL'),
  CandidateItem(id: 'C005', name: '陈丽', desiredJob: '测试工程师', desiredSalary: '12-18K', experience: '2年', education: '大专', skills: 'Selenium, JMeter, Python'),
  CandidateItem(id: 'C006', name: '刘洋', desiredJob: '运维工程师', desiredSalary: '18-25K', experience: '5年', education: '本科', skills: 'K8s, Docker, Linux'),
];

// ---------------------------------------------------------------------------
// JobsService — static service with API-first strategy
// ---------------------------------------------------------------------------

class JobsService {
  JobsService._();

  static final List<JobItem> _jobs = [];
  static bool _apiLoaded = false;

  /// 是否已从API加载真实数据
  static bool get isApiLoaded => _apiLoaded;

  /// 获取职位列表，API优先，失败回退到demo数据
  static List<JobItem> get jobs {
    if (_apiLoaded && _jobs.isNotEmpty) return List.unmodifiable(_jobs);
    return demoJobs;
  }

  /// 获取候选人列表（当前使用演示数据，后续对接API）
  static List<CandidateItem> get candidates => demoCandidates;

  /// 初始化服务，后台加载API数据
  static void init() {
    _loadFromApi();
  }

  static Future<void> _loadFromApi() async {
    try {
      final api = ApiService.instance;
      final result = await api.listJobs();
      final items = result['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        _jobs.clear();
        for (final item in items) {
          _jobs.add(JobItem(
            id: item['id'] as String? ?? '',
            name: item['name'] as String? ?? '',
            salary: item['salary'] as String? ?? '',
            company: item['company'] as String? ?? '',
            location: item['location'] as String? ?? '',
            experience: item['experience'] as String? ?? '',
            education: item['education'] as String? ?? '',
            description: item['description'] as String? ?? '',
          ));
        }
        _apiLoaded = true;
        changeNotifier.value = DateTime.now().millisecondsSinceEpoch;
      }
    } catch (_) {
      // API 不可用，保持演示数据
    }
  }

  /// 通知UI刷新
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
}
