import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 追加
import 'screens/title_screen.dart';
import 'services/socket_service.dart';
import 'services/unity_bridge_service.dart';
import 'providers/user_provider.dart';

// グローバルナビゲーションキー (Overlay表示などに使用)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Flutterエンジンの初期化
  // 以前のコードにある WidgetsFlutterBinding.ensureInitialized() は
  // SharedPreferences を使う前にも必須なのでこの位置で正解です
  WidgetsFlutterBinding.ensureInitialized();

  // --- 修正箇所: SharedPreferences のインスタンスを事前に取得 ---
  final prefs = await SharedPreferences.getInstance();

  // シングルトンサービスのインスタンス生成
  final socketService = SocketService();
  final unityBridge = UnityBridgeService();

  // Socket通信の初期化
  socketService.init("ws://localhost:3000");

  runApp(
    MultiProvider(
      providers: [
        // インフラ層サービスをDI
        Provider.value(value: socketService),
        Provider.value(value: unityBridge),

        // 状態管理・ユースケース層 (MVVM)
        // 修正箇所: unityBridge と prefs の両方を渡す
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
      home: const TitleScreen(),
    );
  }
}