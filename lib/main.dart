import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
//Hello~

// --- ここから追加 ---
void main() {
  runApp(MaterialApp(
    home: BattleScreen(),
  ));
}
// --- ここまで追加 ---

class BattleScreen extends StatefulWidget {
  @override
  _BattleScreenState createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  UnityWidgetController? _unityWidgetController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Unity表示部分
          UnityWidget(
            onUnityCreated: _onUnityCreated,
            onUnityMessage: _onUnityMessage, // Unityからのメッセージ受信
          ),
          // FlutterのUI (ダイスボタンなど)
          Positioned(
            bottom: 50,
            right: 20,
            child: FloatingActionButton(
              onPressed: _sendDiceRoll,
              child: Icon(Icons.casino),
            ),
          ),
        ],
      ),
    );
  }

  // 初期化時の処理
  void _onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
  }

  // Unityからメッセージが来た時の処理
  void _onUnityMessage(dynamic message) {
    print('Received from Unity: $message');
    // 例: "MoveComplete" が来たら次のターンへ
  }

  // Flutter    -> Unity へメッセージ送信
  void _sendDiceRoll() {
    // 第1引数: Unityのオブジェクト名
    // 第2引数: メソッド名
    // 第3引数: 引数(String)       
    _unityWidgetController?.postMessage(
      'GameManager', 
      'OnReceiveFlutterMessage', 
      '{"type": "DiceRolled", "result": 4}'
    );
  }
}
