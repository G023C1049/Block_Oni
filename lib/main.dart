import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 各画面とサービスのインポート
import 'screens/title_screen.dart';
import 'services/socket_service.dart';
import 'services/unity_bridge_service.dart';
import 'providers/user_provider.dart';

// グローバルナビゲーションキー
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Flutterエンジンの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences のインスタンスを事前に取得
  final prefs = await SharedPreferences.getInstance();

  // サービスのインスタンス生成
  final socketService = SocketService();
  final unityBridge = UnityBridgeService();

  // Socket通信の初期化 (環境に合わせてURLを変更してください)
  socketService.init("ws://localhost:3000");

  runApp(
    MultiProvider(
      providers: [
        // インフラ層サービスをDI
        Provider.value(value: socketService),
        Provider.value(value: unityBridge),

        // 状態管理・ユースケース層
        ChangeNotifierProvider(create: (_) => UserProvider(unityBridge, prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ブロックおに',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Colors.white,
      ),
      // アプリ起動時はタイトル画面を表示
      home: const TitleScreen(),
    );
  }
}