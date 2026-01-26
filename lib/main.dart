import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 各画面のインポート
import 'screens/title_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/game_screen.dart';

// サービス・プロバイダーのインポート
import 'services/socket_service.dart';
import 'services/unity_bridge_service.dart';
import 'providers/user_provider.dart';
import 'providers/group_provider.dart';
import 'providers/lobby_view_model.dart';

// グローバルナビゲーションキー
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 画面の向きを横向きに固定（ゲームのため）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final socketService = SocketService();
  final unityBridge = UnityBridgeService();
  
  // Socket通信の初期化
  socketService.init("ws://localhost:3000");

  runApp(
    MultiProvider(
      providers: [
        // インフラ層
        Provider.value(value: socketService),
        Provider.value(value: unityBridge),
        
        // 状態管理層
        ChangeNotifierProvider(create: (_) => UserProvider(unityBridge, prefs)),
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
      // 初期画面
      home: const TitleScreen(),
      // 画面遷移定義
      routes: {
        '/lobby': (context) => const LobbyScreen(),
        '/waiting': (context) => const WaitingRoomScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}