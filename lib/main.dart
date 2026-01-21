import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Block Oni',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E), // 暗めの背景
        primaryColor: Colors.redAccent,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  UnityWidgetController? _unityWidgetController;
  
  // ゲームログ用のリスト
  final List<String> _gameLogs = [
    "システム: ゲームを開始します。",
    "システム: 鬼のターンです。",
  ];

  final ScrollController _scrollController = ScrollController();
  
  // 現在のプレイヤー状態（仮）
  String _currentPlayer = "Oni1";
  bool _isDiceRolled = false;

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Unityとの連携部分 ---

  void _onUnityCreated(controller) {
    _unityWidgetController = controller;
    // 必要なら初期化メッセージを送る
    // _sendMessageToUnity("Init", "");
  }

  void _onUnityMessage(message) {
      try {
        var data = jsonDecode(message.toString());
        
        // ★追加: Unityから計算結果が届いたら詳細ログを出す
        if (data['type'] == 'DiceCalculated') {
          String baseVal = data['base'];
          String bonusVal = data['bonus'];
          String totalVal = data['total'];
          
          // アイテムボーナスがある場合とない場合でメッセージを変えると親切
          if (int.parse(bonusVal) > 0) {
            _addLog("🎲 出目[$baseVal] + アイテム[$bonusVal] = 【$totalValマス】進みます！");
          } else {
            _addLog("🎲 出目[$baseVal] = 【$totalValマス】進みます！");
          }
          return; // これ以上処理しない
        }

      // その他のメッセージ
      _addLog("Unity: $message");
    } catch (e) {
      _addLog("Unity(raw): $message");
    }
  }

  // UnityへJSONメッセージを送る関数
  void _sendMessageToUnity(String type, Map<String, dynamic> data) {
    if (_unityWidgetController != null) {
      data['type'] = type;
      String jsonStr = jsonEncode(data);
      _unityWidgetController!.postMessage(
        'GameManager', // Unity側のGameObject名
        'OnReceiveFlutterMessage', // メソッド名
        jsonStr, // 引数(JSON文字列)
      );
    }
  }

  // --- UIロジック ---

  void _addLog(String text) {
    setState(() {
      _gameLogs.add(text);
    });
    // ログ自動スクロール
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

    int result = Random().nextInt(6) + 1;
    
    // ★修正: ここでは確定メッセージを出さず、送信したことだけ記録する（または何も出さない）
    // _addLog("🎲 ダイスを振りました: 結果 [$result]"); // ←これは削除またはコメントアウト
    _addLog("🎲 ダイスを振っています..."); // ←これに変更

    _sendMessageToUnity("DiceRolled", {"result": result.toString()});

    setState(() {
      _isDiceRolled = true;
    });

    // テスト用リセット（3秒後）
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isDiceRolled = false;
        });
      }
    });
  }

  // --- 画面構築 ---

  @override
  Widget build(BuildContext context) {
    // 横画面レイアウト
    return Scaffold(
      body: Row(
        children: [
          // 左側: Unity画面 (画面の70%)
          Expanded(
            flex: 7,
            child: Container(
              color: Colors.black,
              child: UnityWidget(
                onUnityCreated: _onUnityCreated,
                onUnityMessage: _onUnityMessage,
                useAndroidViewSurface: true, // Androidで安定させる設定
                fullscreen: false,
              ),
            ),
          ),
          
          // 右側: UIパネル (画面の30%)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                border: Border(left: BorderSide(color: Colors.grey, width: 1)),
              ),
              child: Column(
                children: [
                  // 1. ヘッダー (プレイヤー情報)
                  _buildStatusHeader(),
                  const Divider(color: Colors.grey),

                  // 2. ログ表示エリア (スクロール可能)
                  Expanded(
                    child: _buildLogView(),
                  ),
                  const Divider(color: Colors.grey),

                  // 3. アクションエリア (ボタンなど)
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "CURRENT TURN",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
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
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _gameLogs[index],
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        );
      },
    );
  }

  Widget _buildActionArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // ダイスボタン
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isDiceRolled ? null : _handleDiceRoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              icon: const Icon(Icons.casino, size: 28),
              label: const Text(
                "ROLL DICE",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // その他のボタン例
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.grey)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.chat, color: Colors.grey)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}