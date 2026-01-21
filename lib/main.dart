import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 自作ファイルのインポート
import 'screens/title_screen.dart';
import 'services/socket_service.dart';
import 'services/unity_bridge_service.dart';
import 'providers/user_provider.dart';
import 'providers/game_rule_manager.dart';

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
        // インフラ層サービスをDI
        Provider.value(value: socketService),
        Provider.value(value: unityBridge),

        // 状態管理・ユースケース層 (MVVM)
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
      // アプリの起動時はタイトル画面を表示
      home: const TitleScreen(),
    );
  }
}

// --- 以下、ゲーム画面のロジック ---
// ※将来的には lib/screens/game_page.dart に移動推奨

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  UnityWidgetController? _unityWidgetController;
  final GameRuleManager _ruleManager = GameRuleManager();

  final List<String> _gameLogs = [
    "システム: ゲームを開始します。",
    "システム: 10ターン逃げ切れば逃走者の勝ちです。",
  ];

  final ScrollController _scrollController = ScrollController();
  bool _isDiceRolled = false;

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  void _onUnityMessage(message) {
    try {
      var data = jsonDecode(message.toString());
      
      if (data['type'] == 'StatusUpdate') {
        setState(() {
          _ruleManager.gameStatusMessage = data['message'];
        });
        return;
      }

      String? logMessage = _ruleManager.handleUnityMessage(data);
      if (logMessage != null) {
        _addLog(logMessage);
      }
      setState(() {});

    } catch (e) {
      _addLog("Error: $message");
    }
  }

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

    _addLog("🎲 ダイスを振っています...");
    _ruleManager.rollDice(_unityWidgetController);

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

  void _handleUseItem(String itemId, String itemName) {
    if (_unityWidgetController == null) return;
    
    int count = _ruleManager.currentInventory[itemId] ?? 0;
    
    if (count <= 0) {
      _addLog("❌ $itemName を持っていません！");
      return;
    }

    _addLog("✨ アイテム使用: $itemName");
    _ruleManager.useItem(_unityWidgetController, itemId);
    
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
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
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                border: Border(left: BorderSide(color: Colors.grey, width: 1)),
              ),
              child: Column(
                children: [
                  _buildStatusHeader(),
                  const Divider(color: Colors.grey, height: 1),
                  Expanded(child: _buildLogView()),
                  const Divider(color: Colors.grey, height: 1),
                  _buildExpandableItemArea(),
                  const Divider(color: Colors.grey, height: 1),
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Text("GAME INFO", style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _ruleManager.gameStatusMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _gameLogs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            _gameLogs[index],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildExpandableItemArea() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text("ITEMS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: const Text("タップして展開", style: TextStyle(fontSize: 10, color: Colors.grey)),
        initiallyExpanded: false,
        children: [
          Container(
            height: 100, 
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.black12,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildItemButton("SpeedUp", "加速(+2)", Icons.flash_on, Colors.yellow),
                const SizedBox(width: 8),
                _buildItemButton("Teleport", "ワープ", Icons.wifi_tethering, Colors.purpleAccent),
                const SizedBox(width: 8),
                _buildItemButton("StageRotate", "回転", Icons.rotate_right, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemButton(String id, String name, IconData icon, Color color) {
    int count = _ruleManager.currentInventory[id] ?? 0;
    bool hasItem = count > 0;

    return InkWell(
      onTap: hasItem ? () => _handleUseItem(id, name) : null,
      child: Container(
        width: 70, 
        decoration: BoxDecoration(
          color: hasItem ? color.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasItem ? color : Colors.grey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: hasItem ? color : Colors.grey, size: 24),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(name, style: TextStyle(color: hasItem ? Colors.white : Colors.grey, fontSize: 10)),
            ),
            Text("x$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isDiceRolled ? null : _handleDiceRoll,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.casino, size: 24),
          label: const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("ROLL DICE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}