import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/providers/user_provider.dart';
import '../lib/services/unity_bridge_service.dart';

// UnityBridgeServiceのスタブ（テスト用）
class FakeUnityBridge extends UnityBridgeService {
  @override
  void sendToUnity(String methodName, dynamic data) {
    // テスト中は何もしない、あるいはログ出力など
  }
}

void main() {
  late SharedPreferences prefs;
  late UserProvider provider;

  setUp(() async {
    // 1. Mock値をセット
    SharedPreferences.setMockInitialValues({});
    // 2. インスタンスを取得
    prefs = await SharedPreferences.getInstance();
    // 3. 2つの引数を渡して初期化（これでエラーが消えます）
    provider = UserProvider(FakeUnityBridge(), prefs);
  });

  test('A-S-01 名前登録 正常', () async {
    expect(await provider.saveUsername('テスト太郎'), true);
  });

  test('A-S-02 名前永続化', () async {
    await provider.saveUsername('テスト太郎');
    expect(prefs.getString('user_name'), 'テスト太郎');
  });

  test('A-E-01 空文字', () async {
    // 空文字や空白のみは false になるべき
    expect(await provider.saveUsername(''), false);
    expect(await provider.saveUsername('   '), false);
  });

  test('A-E-02 13文字以上', () async {
    expect(await provider.saveUsername('1234567890123'), false);
  });

  test('A-E-03 絵文字', () async {
    // 絵文字が含まれる場合に弾くロジックをProvider側に追加済み
    expect(await provider.saveUsername('太郎😀'), false);
  });
}