import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===== 自作ファイル =====
import 'screens/title_screen.dart';
import 'services/socket_service.dart';
import 'services/unity_bridge_service.dart';
import 'providers/user_provider.dart';

// ===== グローバルNavigatorKey =====
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// =======================================================
// main
// =======================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final socketService = SocketService();
  final unityBridge = UnityBridgeService();

  socketService.init("ws://localhost:3000");

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: socketService),
        Provider.value(value: unityBridge),
        ChangeNotifierProvider(
          create: (_) => UserProvider(unityBridge, prefs),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// =======================================================
// MyApp
// =======================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Block Oni',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.redAccent,
      ),
      home: const TitleScreen(), // ← タイトル → GamePageへ
    );
  }
}

// =======================================================
// GamePage（Unity連携メイン画面）
// =======================================================
class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  UnityWidgetController? _unityWidgetController;

  final List<String> _gameLogs = [
    "システム: ゲームを開始します。",
    "システム: 鬼のターンです。",
  ];

  final ScrollController _scrollController = ScrollController();

  String _currentPlayer = "Oni1";
  bool _isDiceRolled = false;

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =====================================================
  // Unity連携
  // =====================================================
  void _onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  void _onUnityMessage(message) {
    try {
      final data = jsonDecode(message.toString());

      if (data['type'] == 'DiceCalculated') {
        final baseVal = data['base'];
        final bonusVal = data['bonus'];
        final totalVal = data['total'];

        if (int.parse(bonusVal) > 0) {
          _addLog("🎲 出目[$baseVal] + アイテム[$bonusVal] = 【$totalValマス】進みます！");
        } else {
          _addLog("🎲 出目[$baseVal] = 【$totalValマス】進みます！");
        }
        return;
      }

      _addLog("Unity: $message");
    } catch (e) {
      _addLog("Unity(raw): $message");
    }
  }

  void _sendMessageToUnity(String type, Map<String, dynamic> data) {
    if (_unityWidgetController == null) return;

    data['type'] = type;

    _unityWidgetController!.postMessage(
      'GameManager',
      'OnReceiveFlutterMessage',
      jsonEncode(data),
    );
  }

  // =====================================================
  // UIロジック
  // =====================================================
  void _addLog(String text) {
    setState(() {
      _gameLogs.add(text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleDiceRoll() {
    if (_isDiceRolled) return;

    final result = Random().nextInt(6) + 1;

    _addLog("🎲 ダイスを振っています...");
    _sendMessageToUnity("DiceRolled", {"result": result.toString()});

    setState(() {
      _isDiceRolled = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isDiceRolled = false;
        });
      }
    });
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Unity画面
          Expanded(
            flex: 7,
            child: Container(
              color: Colors.black,
              child: UnityWidget(
                onUnityCreated: _onUnityCreated,
                onUnityMessage: _onUnityMessage,
                useAndroidViewSurface: true,
                fullscreen: false,
              ),
            ),
          ),

          // UIパネル
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                border: Border(left: BorderSide(color: Colors.grey)),
              ),
              child: Column(
                children: [
                  _buildStatusHeader(),
                  const Divider(),
                  Expanded(child: _buildLogView()),
                  const Divider(),
                  _buildActionArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("CURRENT TURN", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(
              _currentPlayer,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _gameLogs.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          _gameLogs[i],
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isDiceRolled ? null : _handleDiceRoll,
              icon: const Icon(Icons.casino, size: 28),
              label: const Text(
                "ROLL DICE",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Icon(Icons.settings, color: Colors.grey),
              Icon(Icons.chat, color: Colors.grey),
              Icon(Icons.help_outline, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
