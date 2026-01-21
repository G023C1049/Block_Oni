import 'dart:convert';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

/// 責務: Flutter と Unity 間の低レイヤー通信を抽象化 [cite: 53-54]
class UnityBridgeService {
  UnityWidgetController? _unityWidgetController;

  // Unityウィジェットが生成されたらコントローラーをセットする
  void setController(UnityWidgetController controller) {
    _unityWidgetController = controller;
  }

  /// Flutter -> Unity: メッセージ送信 [cite: 55]
  void sendToUnity(String method, Map<String, dynamic> args) {
    // 設計書の通信フォーマット案に基づくJSON作成 [cite: 61-68]
    final String message = jsonEncode({
      "api": "FlutterToUnity",
      "method": method,
      "parameters": args,
    });

    // Unity側の 'UnityReceiverObject' というオブジェクトの 'OnMessageFromFlutter' メソッドを呼ぶ
    _unityWidgetController?.postMessage(
      'UnityReceiverObject', 
      'OnMessageFromFlutter',
      message,
    );
  }

  /// Unity -> Flutter: メッセージ受信処理 [cite: 57]
  void onMessageFromUnity(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message.toString());
      final String type = data['type'] ?? '';

      // 必要に応じてProviderのメソッドを呼び出す処理をここに記述
      print("Received from Unity: $type");
      
    } catch (e) {
      print("Unity Message Parse Error: $e");
    }
  }
}