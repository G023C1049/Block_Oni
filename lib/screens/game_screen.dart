import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:provider/provider.dart';
import '../providers/game_rule_manager.dart';
import '../providers/user_provider.dart';
import '../models/game_types.dart'; // WinState用
import '../models/player.dart';     // PlayerRole用
import 'result_screen.dart';        // リザルト画面

class GameScreen extends StatefulWidget {
  const GameScreen({super.key}); // warning修正

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  UnityWidgetController? _unityWidgetController;
  final GameRuleManager _ruleManager = GameRuleManager();

  final List<String> _gameLogs = [
    "システム: ゲーム画面をロード中...",
  ];

  final ScrollController _scrollController = ScrollController();
  bool _isDiceRolled = false;
  bool _hasSentInitInfo = false;
  
  // 自分の役職 (player.dartの定義を使用)
  PlayerRole _myRole = PlayerRole.Runner;

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // warning修正: 型を明記
  void _onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
    
    Future.delayed(const Duration(seconds: 3), () {
      if (!_hasSentInitInfo && mounted) {
        _sendGameInitInfo();
      }
    });
  }

  void _sendGameInitInfo() {
    if (_unityWidgetController == null) return;
    
    final userProvider = context.read<UserProvider>();
    final userName = userProvider.username;

    debugPrint("Sending StartGame to Unity with name: $userName");

    final message = jsonEncode({
      "type": "StartGame",
      "userName": userName.isNotEmpty ? userName : "Guest"
    });

    _unityWidgetController?.postMessage(
      'GameManager',
      'OnReceiveFlutterMessage',
      message,
    );
    
    _hasSentInitInfo = true;
    
    if (!_gameLogs.any((log) => log.contains("ゲームに参加しました"))) {
       _addLog("システム: $userName としてゲームに参加しました。");
    }
  }

  // warning修正: 型を明記
  void _onUnityMessage(dynamic message) {
    try {
      var data = jsonDecode(message.toString());

      if (data['type'] == 'GameReady') {
        _sendGameInitInfo();
        return;
      }

      if (data['type'] == 'StatusUpdate') {
        setState(() {
          _ruleManager.gameStatusMessage = data['message'];
        });
        return;
      }

      // 役職割り当てメッセージの処理
      if (data['type'] == 'RoleAssigned') {
        final roleStr = data['role'];
        setState(() {
          if (roleStr == "Oni") {
            _myRole = PlayerRole.Oni;
            _addLog("あなたの役職は【鬼】です！逃走者を捕まえろ！");
          } else {
            _myRole = PlayerRole.Runner;
            _addLog("あなたの役職は【逃走者】です！鬼から逃げ切れ！");
          }
        });
        return;
      }

      // ゲーム終了メッセージの処理 -> リザルト画面へ
      if (data['type'] == 'GameEnd') {
        final resultStr = data['result']; // "OniWin" or "RunnerWin"
        WinState winState;
        
        if (resultStr == "OniWin") {
          winState = WinState.OniWin;
        } else {
          winState = WinState.RunnerWin;
        }

        // リザルト画面へ遷移
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                winState: winState,
                myRole: _myRole,
                onReturnToLobby: () {
                  // ロビー(前の画面)まで戻る
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          );
        }
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
      appBar: AppBar(
        title: const Text('ゲームプレイ'),
        backgroundColor: const Color(0xFF252525),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             Navigator.of(context).pop();
          },
        ),
      ),
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
              child: SafeArea(
                bottom: true, 
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
            height: 90, 
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
          // warning修正: withOpacity -> withValues
          color: hasItem ? color.withValues(alpha: 0.2) : Colors.black26,
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
      ),
    );
  }
}