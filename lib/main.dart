import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 自作ファイルのインポート (インフラ・共通)
import 'screens/title_screen.dart';
import 'services/socket_service.dart';
import 'services/unity_bridge_service.dart';
import 'providers/user_provider.dart';

// 自作ファイルのインポート (ロビー・グループ機能 - maruch-screen2から追加)
import 'providers/group_provider.dart';
import 'providers/lobby_view_model.dart';
import 'screens/lobby_screen.dart'; // 将来的に遷移先として必要になる可能性があります

// グローバルナビゲーションキー (Overlay表示などに使用)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Flutterエンジンの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences のインスタンスを事前に取得
  final prefs = await SharedPreferences.getInstance();

  // シングルトンサービスのインスタンス生成
  final socketService = SocketService();
  final unityBridge = UnityBridgeService();

  // Socket通信の初期化
  socketService.init("ws://localhost:3000");

  runApp(
    MultiProvider(
      providers: [
        // --- インフラ層サービスをDI (main由来) ---
        Provider.value(value: socketService),
        Provider.value(value: unityBridge),

        // --- 状態管理・ユースケース層 (main由来) ---
        ChangeNotifierProvider(create: (_) => UserProvider(unityBridge, prefs)),

        // --- ロビー・グループ管理 (maruch-screen2由来) ---
        // ここに追加しました！
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => LobbyViewModel()),
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
      // アプリの起動時はタイトル画面を表示
      home: const TitleScreen(),
    );
  }
}