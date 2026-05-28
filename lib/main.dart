import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'pages/chat_page.dart';
import 'pages/friends_page.dart';
import 'pages/plaza_page.dart';
import 'pages/settings_page.dart';
import 'pages/services_page.dart';
import 'pages/login_page.dart';
import 'services/auth_provider.dart';

void main() {
  // 初始化腾讯IM（占位值，后续替换真实SDKAppID和userSig）
  TencentImSDKPlugin.v2TIMManager.initSDK(
    sdkAppID: 1400000000,
    loglevel: 0,
    listener: V2TimSDKListener(),
  );
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
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




