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
import 'services/auth_provider.dart';
import 'services/websocket_service.dart';
import 'services/api_service.dart';

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

class DochatappApp extends ConsumerWidget {
  const DochatappApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoApp(
      title: '电邮',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.white,
        textTheme: const CupertinoTextThemeData(
          primaryColor: CupertinoColors.black,
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Gate — checks token and shows Login or MainScreen
// ---------------------------------------------------------------------------

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Check for stored token on startup
    ref.read(authProvider.notifier).checkAuth();
  }

  @override
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

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    // 首帧后尝试连接 WebSocket（使用 ref.read 是允许的）
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectCallWs());
  }

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
    await WebSocketService.shared.connect(userId);
    if (mounted) setState(() => _wsConnected = true);
  }

  void _onIncomingCall(WsChatMessage msg) {
    if (!mounted) return;

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
          callId: msg.msgId ?? '',
          callType: callTypeStr == 'video' ? CallType.video : CallType.audio,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WebSocketService.shared.offCallStart(_onIncomingCall);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 auth 状态变化（ref.listen 只能在 build 方法中调用）
    ref.listen<AuthState>(authProvider, (AuthState? prev, AuthState next) {
      if (next.status == AuthStatus.authenticated && !_wsConnected) {
        _connectCallWs();
      } else if (next.status == AuthStatus.unauthenticated) {
        WebSocketService.shared.dispose();
        _wsConnected = false;
      }
    });

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: CupertinoColors.systemBlue,
        inactiveColor: CupertinoColors.systemGrey,
        backgroundColor: CupertinoColors.white,
        border: const Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
        height: 50,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            activeIcon: Icon(CupertinoIcons.chat_bubble_fill),
            label: '聊天',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: '好友',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.globe),
            activeIcon: Icon(CupertinoIcons.globe),
            label: '广场',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: '服务',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear),
            activeIcon: Icon(CupertinoIcons.gear_solid),
            label: '设置',
          ),
        ],
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
}




