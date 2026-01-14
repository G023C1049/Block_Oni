import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// プロジェクト名に合わせて変更してください
import 'package:block_oni_app/main.dart'; 

void main() {
  testWidgets('BattleScreen display test', (WidgetTester tester) async {
    // MyApp() ではなく BattleScreen() を呼び出す
    // UnityWidgetが含まれるため、MaterialAppでラップするのが安全です
    await tester.pumpWidget(MaterialApp(
      home: BattleScreen(),
    ));

    // Verify: 浮遊アクションボタン（サイコロアイコン）が存在するか確認
    expect(find.byIcon(Icons.casino), findsOneWidget);
  });
}