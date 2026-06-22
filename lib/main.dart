// 鐢垫尝鐏靛姩鍗虫椂閫氳绯荤粺 V1.0
// 钁椾綔鏉冧汉锛氭睙鑻忔牘鐔欐櫒姊︾綉缁滅鎶€鏈夐檺鍏徃
// 寮€鍙戝畬鎴愭棩鏈燂細2026骞?鏈?8鏃?
// 鏂囦欢璇存槑锛氬簲鐢ㄥ叆鍙ｄ笌涓荤晫闈㈡鏋?

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
import 'services/notification_service.dart';

  /// 搴旂敤鍏ュ彛鍑芥暟锛屽垵濮嬪寲鑵捐IM SDK骞跺惎鍔ㄥ簲鐢?
void main() {
  // 鍒濆鍖栬吘璁疘M锛堝崰浣嶅€硷紝鍚庣画鏇挎崲鐪熷疄SDKAppID鍜寀serSig锛?
  if (!kIsWeb) {
    TencentImSDKPlugin.v2TIMManager.initSDK(
      sdkAppID: 1600148063,
      loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
      listener: V2TimSDKListener(),
    );
  }
  runApp(const ProviderScope(child: DochatappApp()));
}

// ---------------------------------------------------------------------------
// Root App
// ---------------------------------------------------------------------------

/// 搴旂敤鏍圭粍浠讹紝閰嶇疆Cupertino涓婚鍜岃矾鐢?
class DochatappApp extends ConsumerWidget {
  const DochatappApp({super.key});

  @override
  /// 鏋勫缓Widget鏍?
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    return CupertinoApp(
      title: '鐢甸偖',
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
// Auth Gate 鈥?checks token and shows Login or MainScreen
// ---------------------------------------------------------------------------

/// 璁よ瘉鐘舵€佺綉鍏筹紝鏍规嵁鐧诲綍鐘舵€佹樉绀虹櫥褰曢〉鎴栦富椤?
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  /// 鍒濆鍖栫姸鎬侊紝妫€鏌ヨ璇佺姸鎬?
  void initState() {
    super.initState();
    // Check for stored token on startup
    ref.read(authProvider.notifier).checkAuth();
  }

  @override
  /// 鏋勫缓Widget鏍?
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

/// 涓诲鑸〉闈紝鍖呭惈搴曢儴Tab鏍忓拰WebSocket杩炴帴绠＄悊
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _wsConnected = false;
  String? _activeIncomingCallId;
  int _friendBadge = 0; // 濂藉弸鐢宠瑙掓爣鏁?
  int _serviceBadge = 0; // 鏈嶅姟Tab鎬昏鏍?

  @override
  /// 鍒濆鍖栫姸鎬侊紝妫€鏌ヨ璇佺姸鎬?
  void initState() {
    super.initState();
    // 绔嬪嵆浠庡綋鍓?notifier 鍊煎垵濮嬪寲瑙掓爣锛堥伩鍏嶉甯ф樉绀?0锛?
    _friendBadge = FriendsPage.pendingRequestNotifier.value;
    _serviceBadge = NotificationService.totalNotifier.value;
    // 鐩戝惉鍏ㄥ眬寰呭鐞嗙敵璇锋暟鍙樺寲
    FriendsPage.pendingRequestNotifier.addListener(_onFriendBadgeChanged);
    NotificationService.totalNotifier.addListener(_onServiceBadgeChanged);
    // 棣栧抚鍚庡皾璇曡繛鎺?WebSocket 骞堕鍔犺浇瑙掓爣
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectCallWs();
      _initFriendBadge();
      NotificationService.init();
    });
  }

  /// 鍏ㄥ眬寰呭鐞嗙敵璇锋暟鍙樺寲鏃跺悓姝ヨ鏍?
  void _onFriendBadgeChanged() {
    if (mounted) {
      setState(() => _friendBadge = FriendsPage.pendingRequestNotifier.value);
    }
  }

  void _onServiceBadgeChanged() {
    if (mounted) {
      setState(() => _serviceBadge = NotificationService.totalNotifier.value);
    }
  }

  /// 棰勫姞杞藉ソ鍙嬬敵璇疯鏍囷紙鍦ㄥソ鍙嬮〉闈㈠垵濮嬪寲鍓嶏級
  Future<void> _initFriendBadge() async {
    try {
      final data = await ApiService.instance.getFriendRequests();
      if (mounted) {
        final count = data.length;
        setState(() => _friendBadge = count);
        FriendsPage.pendingRequestNotifier.value = count;
      }
    } catch (_) {
      // API 澶辫触鏃朵娇鐢ㄦ紨绀哄€?3锛屼笌 friends_page 淇濇寔涓€鑷?
      if (mounted) {
        setState(() => _friendBadge = 3);
        FriendsPage.pendingRequestNotifier.value = 3;
      }
    }
  }

  /// 寤虹珛WebSocket閫氳瘽淇′护杩炴帴
  Future<void> _connectCallWs() async {
    if (_wsConnected) return;

    // 1) 浠?auth state 鑾峰彇 userId
    String? userId;
    final authState = ref.read(authProvider);
    userId = authState.user?['id'] as String?;

    // 2) 濡傛灉 auth state 娌℃湁锛坈heckAuth 寮傛鍔犺浇 profile 灏氭湭瀹屾垚锛夛紝
    //    鐩存帴閫氳繃 API 鑾峰彇鐢ㄦ埛淇℃伅
    if (userId == null || userId.isEmpty) {
      try {
        final profile = await ApiService.instance.getProfile();
        userId = profile['id'] as String?;
      } catch (_) {
        // API 涔熷け璐ワ紝鏃犳硶杩炴帴 WebSocket
        return;
      }
    }

    if (userId == null || userId.isEmpty) return;

    WebSocketService.shared.onCallStart(_onIncomingCall);
    WebSocketService.shared.onCallEnd(_onCallEndForIncoming);
    await WebSocketService.shared.connect(userId);
    if (mounted) setState(() => _wsConnected = true);
  }

  /// 澶勭悊鏉ョ數娑堟伅锛屽脊鍑烘帴鍚〉闈?
  void _onIncomingCall(WsChatMessage msg) {
    if (!mounted) return;

    final callId = msg.msgId ?? '';
    // 闃叉閲嶅鎺ㄩ€侊細鍚屼竴 callId 鐨勬潵鐢靛彧寮逛竴娆?IncomingCallPage
    if (_activeIncomingCallId == callId) return;
    _activeIncomingCallId = callId;

    // Parse payload: Content is JSON {"call_type":"...","caller_name":"..."}
    String callTypeStr = 'audio';
    String callerName = '鏈煡';
    try {
      if (msg.content.startsWith('{')) {
        final map = jsonDecode(msg.content) as Map<String, dynamic>;
        callTypeStr = map['call_type'] as String? ?? 'audio';
        callerName = map['caller_name'] as String? ?? '鏈煡';
      } else {
        callTypeStr = msg.content; // fallback: plain call_type
      }
    } catch (_) {
      // ignore parse errors
    }

    // If callerName is still empty, try to get it from callerId as fallback
    if (callerName.isEmpty || callerName == '鏈煡') {
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
      // IncomingCallPage 琚叧闂椂锛堟帴鍙?鎷掓帴/瀵规柟鍙栨秷锛夛紝娓呴櫎娲昏穬鏉ョ數ID
      if (_activeIncomingCallId == callId) {
        _activeIncomingCallId = null;
      }
    });
  }

  /// 澶勭悊瀵规柟鎸傛柇/鍙栨秷閫氳瘽浜嬩欢锛堝畨鍏ㄧ綉锛氭竻闄ゆ椿璺冩潵鐢礗D锛岄槻姝㈣繃鏈?call-start 閲嶅寮圭獥锛?
  void _onCallEndForIncoming(WsChatMessage msg) {
    if (_activeIncomingCallId == msg.msgId) {
      _activeIncomingCallId = null;
    }
  }

  @override
  /// 閲婃斁璧勬簮锛屽彇娑圵ebSocket鐩戝惉
  void dispose() {
    FriendsPage.pendingRequestNotifier.removeListener(_onFriendBadgeChanged);
    NotificationService.totalNotifier.removeListener(_onServiceBadgeChanged);
    WebSocketService.shared.offCallStart(_onIncomingCall);
    WebSocketService.shared.offCallEnd(_onCallEndForIncoming);
    super.dispose();
  }

  @override
  /// 鏋勫缓Widget鏍?
  Widget build(BuildContext context) {
    // 鐩戝惉娣辫壊妯″紡锛岃仈鍔ㄥ簳閮ㄥ鑸爮棰滆壊
    final isDark = ref.watch(darkModeProvider);

    // 鐩戝惉 auth 鐘舵€佸彉鍖栵紙ref.listen 鍙兘鍦?build 鏂规硶涓皟鐢級
    ref.listen<AuthState>(authProvider, (AuthState? prev, AuthState next) {
      if (next.status == AuthStatus.authenticated && !_wsConnected) {
        _connectCallWs();
      } else if (next.status == AuthStatus.unauthenticated) {
        WebSocketService.shared.dispose();
        _wsConnected = false;
      }
    });

    // 鍔ㄦ€佹瀯寤哄簳閮ㄥ鑸爮椤癸紙濂藉弸Tab甯﹁鏍囷紝鏈嶅姟Tab甯︾洿鑱樿鏍囷級
    final badge = _friendBadge;
    final serviceBadge = _serviceBadge;
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.chat_bubble),
        activeIcon: Icon(CupertinoIcons.chat_bubble_fill),
        label: '鑱婂ぉ',
      ),
      BottomNavigationBarItem(
        icon: _buildTabIcon(CupertinoIcons.person_2, badge),
        activeIcon: _buildTabIcon(CupertinoIcons.person_2_fill, badge),
        label: '濂藉弸',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.globe),
        activeIcon: Icon(CupertinoIcons.globe),
        label: '骞垮満',
      ),
      BottomNavigationBarItem(
        icon: _buildTabIcon(CupertinoIcons.square_grid_2x2, serviceBadge),
        activeIcon: _buildTabIcon(CupertinoIcons.square_grid_2x2_fill, serviceBadge),
        label: '鏈嶅姟',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.gear),
        activeIcon: Icon(CupertinoIcons.gear_solid),
        label: '璁剧疆',
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

  /// 鏋勫缓甯﹁鏍囩殑搴曢儴瀵艰埅鏍忓浘鏍?
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






