// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：应用入口与主界面框架

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'pages/chat_page.dart';
import 'pages/friends_page.dart';
import 'pages/plaza_page.dart';
import 'pages/settings_page.dart';
import 'pages/services_page.dart';
import 'pages/login_page.dart';
import 'pages/incoming_call_page.dart';
import 'pages/call_page.dart';
import 'providers/theme_provider.dart';
import 'services/auth_provider.dart';
import 'services/websocket_service.dart';
import 'services/api_service.dart';
import 'services/jobs_badge_service.dart';

  /// 应用入口函数，初始化腾讯IM SDK并启动应用
void main() {
  // 初始化腾讯IM（占位值，后续替换真实SDKAppID和userSig）
  if (!kIsWeb) {
    TencentImSDKPlugin.v2TIMManager.initSDK(
      sdkAppID: 1400000000,
      loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
      listener: V2TimSDKListener(),
    );
  }
  runApp(const ProviderScope(child: DochatappApp()));
}

// ---------------------------------------------------------------------------
// Root App
// ---------------------------------------------------------------------------

/// 应用根组件，配置Cupertino主题和路由
class DochatappApp extends ConsumerWidget {
  const DochatappApp({super.key});

  @override
  /// 构建Widget树
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    return CupertinoApp(
      title: '电邮',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        barBackgroundColor: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          primaryColor: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Gate — checks token and shows Login or MainScreen
// ---------------------------------------------------------------------------

/// 认证状态网关，根据登录状态显示登录页或主页
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  /// 初始化状态，检查认证状态
  void initState() {
    super.initState();
    // Check for stored token on startup
    ref.read(authProvider.notifier).checkAuth();
  }

  @override
  /// 构建Widget树
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.initial:
        return const CupertinoPageScaffold(
          backgroundColor: Color(0xFFF2F2F7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.mail_solid, size: 48, color: CupertinoColors.activeBlue),
                SizedBox(height: 16),
                CupertinoActivityIndicator(),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const MainScreen();
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}

// ---------------------------------------------------------------------------
// Main Tab Screen
// ---------------------------------------------------------------------------

/// 主导航页面，包含底部Tab栏和WebSocket连接管理
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _wsConnected = false;
  String? _activeIncomingCallId;
  int _friendBadge = 0; // 好友申请角标数
  int _jobsBadge = 0; // 直聘角标数

  @override
  /// 初始化状态，检查认证状态
  void initState() {
    super.initState();
    // 监听全局待处理申请数变化
    FriendsPage.pendingRequestNotifier.addListener(_onFriendBadgeChanged);
    JobsBadgeService.badgeNotifier.addListener(_onJobsBadgeChanged);
    // 首帧后尝试连接 WebSocket 并预加载角标
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectCallWs();
      _initFriendBadge();
      JobsBadgeService.init();
    });
  }

  /// 全局待处理申请数变化时同步角标
  void _onFriendBadgeChanged() {
    if (mounted) {
      setState(() => _friendBadge = FriendsPage.pendingRequestNotifier.value);
    }
  }

  void _onJobsBadgeChanged() {
    if (mounted) {
      setState(() => _jobsBadge = JobsBadgeService.badgeNotifier.value);
    }
  }

  /// 预加载好友申请角标（在好友页面初始化前）
  Future<void> _initFriendBadge() async {
    try {
      final data = await ApiService.instance.getFriendRequests();
      if (mounted) {
        final count = data.length;
        setState(() => _friendBadge = count);
        FriendsPage.pendingRequestNotifier.value = count;
      }
    } catch (_) {
      // API 失败时使用演示值 3，与 friends_page 保持一致
      if (mounted) {
        setState(() => _friendBadge = 3);
        FriendsPage.pendingRequestNotifier.value = 3;
      }
    }
  }

  /// 建立WebSocket通话信令连接
  Future<void> _connectCallWs() async {
    if (_wsConnected) return;

    // 1) 从 auth state 获取 userId
    String? userId;
    final authState = ref.read(authProvider);
    userId = authState.user?['id'] as String?;

    // 2) 如果 auth state 没有（checkAuth 异步加载 profile 尚未完成），
    //    直接通过 API 获取用户信息
    if (userId == null || userId.isEmpty) {
      try {
        final profile = await ApiService.instance.getProfile();
        userId = profile['id'] as String?;
      } catch (_) {
        // API 也失败，无法连接 WebSocket
        return;
      }
    }

    if (userId == null || userId.isEmpty) return;

    WebSocketService.shared.onCallStart(_onIncomingCall);
    WebSocketService.shared.onCallEnd(_onCallEndForIncoming);
    await WebSocketService.shared.connect(userId);
    if (mounted) setState(() => _wsConnected = true);
  }

  /// 处理来电消息，弹出接听页面
  void _onIncomingCall(WsChatMessage msg) {
    if (!mounted) return;

    final callId = msg.msgId ?? '';
    // 防止重复推送：同一 callId 的来电只弹一次 IncomingCallPage
    if (_activeIncomingCallId == callId) return;
    _activeIncomingCallId = callId;

    // Parse payload: Content is JSON {"call_type":"...","caller_name":"..."}
    String callTypeStr = 'audio';
    String callerName = '未知';
    try {
      if (msg.content.startsWith('{')) {
        final map = jsonDecode(msg.content) as Map<String, dynamic>;
        callTypeStr = map['call_type'] as String? ?? 'audio';
        callerName = map['caller_name'] as String? ?? '未知';
      } else {
        callTypeStr = msg.content; // fallback: plain call_type
      }
    } catch (_) {
      // ignore parse errors
    }

    // If callerName is still empty, try to get it from callerId as fallback
    if (callerName.isEmpty || callerName == '未知') {
      callerName = msg.fromId;
    }

    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => IncomingCallPage(
          callerName: callerName,
          callerId: msg.fromId,
          callId: callId,
          callType: callTypeStr == 'video' ? CallType.video : CallType.audio,
        ),
      ),
    ).then((_) {
      // IncomingCallPage 被关闭时（接受/拒接/对方取消），清除活跃来电ID
      if (_activeIncomingCallId == callId) {
        _activeIncomingCallId = null;
      }
    });
  }

  /// 处理对方挂断/取消通话事件（安全网：清除活跃来电ID，防止过期 call-start 重复弹窗）
  void _onCallEndForIncoming(WsChatMessage msg) {
    if (_activeIncomingCallId == msg.msgId) {
      _activeIncomingCallId = null;
    }
  }

  @override
  /// 释放资源，取消WebSocket监听
  void dispose() {
    FriendsPage.pendingRequestNotifier.removeListener(_onFriendBadgeChanged);
    JobsBadgeService.badgeNotifier.removeListener(_onJobsBadgeChanged);
    WebSocketService.shared.offCallStart(_onIncomingCall);
    WebSocketService.shared.offCallEnd(_onCallEndForIncoming);
    super.dispose();
  }

  @override
  /// 构建Widget树
  Widget build(BuildContext context) {
    // 监听深色模式，联动底部导航栏颜色
    final isDark = ref.watch(darkModeProvider);

    // 监听 auth 状态变化（ref.listen 只能在 build 方法中调用）
    ref.listen<AuthState>(authProvider, (AuthState? prev, AuthState next) {
      if (next.status == AuthStatus.authenticated && !_wsConnected) {
        _connectCallWs();
      } else if (next.status == AuthStatus.unauthenticated) {
        WebSocketService.shared.dispose();
        _wsConnected = false;
      }
    });

    // 动态构建底部导航栏项（好友Tab带角标，服务Tab带直聘角标）
    final badge = _friendBadge;
    final jobsBadge = _jobsBadge;
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.chat_bubble),
        activeIcon: Icon(CupertinoIcons.chat_bubble_fill),
        label: '聊天',
      ),
      BottomNavigationBarItem(
        icon: _buildTabIcon(CupertinoIcons.person_2, badge),
        activeIcon: _buildTabIcon(CupertinoIcons.person_2_fill, badge),
        label: '好友',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.globe),
        activeIcon: Icon(CupertinoIcons.globe),
        label: '广场',
      ),
      BottomNavigationBarItem(
        icon: _buildTabIcon(CupertinoIcons.square_grid_2x2, jobsBadge),
        activeIcon: _buildTabIcon(CupertinoIcons.square_grid_2x2_fill, jobsBadge),
        label: '服务',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.gear),
        activeIcon: Icon(CupertinoIcons.gear_solid),
        label: '设置',
      ),
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        key: ValueKey('main_tabbar_$isDark'),
        activeColor: CupertinoColors.systemBlue,
        inactiveColor: isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF38383A) : CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
        height: 50,
        items: items,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return const ChatPage();
              case 1:
                return const FriendsPage();
              case 2:
                return const PlazaPage();
              case 3:
                return const ServicesPage();
              case 4:
                return const SettingsPage();
              default:
                return const ChatPage();
            }
          },
        );
      },
    );
  }

  /// 构建带角标的底部导航栏图标
  Widget _buildTabIcon(IconData icon, int badge) {
    if (badge <= 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -6,
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
    );
  }
}




