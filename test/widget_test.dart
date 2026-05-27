import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dochatapp/main.dart';

void main() {
  testWidgets('App shows 5 bottom tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DochatappApp()));

    // Verify that all 5 tab labels are present
    expect(find.text('聊天'), findsWidgets);
    expect(find.text('好友'), findsWidgets);
    expect(find.text('广场'), findsWidgets);
    expect(find.text('服务'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
  });
}
