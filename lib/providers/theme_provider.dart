// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：深色模式状态管理

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 深色模式全局状态，默认关闭（浅色模式）
final darkModeProvider = StateProvider<bool>((ref) => false);
