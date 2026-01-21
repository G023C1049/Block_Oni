import 'dart:convert';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/game_data.dart';

class GameRuleManager {
  int currentTurn = 1;
  int maxTurn = 10;
  String currentPlayerId = "Runner"; // 初期プレイヤー
  String gameStatusMessage = "ゲーム開始待機中";
  bool hasRolledThisTurn = false;

  // ★修正: プレイヤーごとのインベントリ管理
  // Map<PlayerID, Map<ItemID, Count>>
  Map<String, Map<String, int>> allPlayerInventories = {
    "Runner": {},
    "Oni1": {},
    "Oni2": {},
    "Oni3": {},
  };

  // 現在のプレイヤーの在庫を取得するヘルパー
  Map<String, int> get currentInventory => allPlayerInventories[currentPlayerId] ?? {};

  void sendToUnity(UnityWidgetController? controller, String type, Map<String, dynamic> data) {
    if (controller == null) return;
    data['type'] = type;
    controller.postMessage(
      'GameManager',
      'OnReceiveFlutterMessage',
      jsonEncode(data),
    );
  }

  void rollDice(UnityWidgetController? controller) {
    if (hasRolledThisTurn) return; 

    int result = DateTime.now().millisecond % 6 + 1; 
    sendToUnity(controller, "DiceRolled", {"result": result.toString()});
    hasRolledThisTurn = true;
  }

  void useItem(UnityWidgetController? controller, String itemId) {
    // 現在のプレイヤーの所持数をチェック
    int count = currentInventory[itemId] ?? 0;
    if (count <= 0) {
      return; 
    }
    
    // Unityへ使用リクエスト
    sendToUnity(controller, "UseItem", {"itemId": itemId});
    
    // UI上ですぐ減らす（Unity側で却下される可能性もあるが、基本は信頼する）
    // もし厳密にするならUnityからの成功通知を待つべきだが、今回は簡易実装
    currentInventory[itemId] = count - 1;
  }

  String? handleUnityMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'UnityReady':
        return "System: Unity Connected.";

      case 'TurnChange':
        hasRolledThisTurn = false; 
        currentPlayerId = data['playerId']; // 手番プレイヤー更新
        return "Turn changed to $currentPlayerId";

      case 'StatusUpdate':
        return null;

      case 'DiceCalculated':
        String baseVal = data['base'];
        String bonusVal = data['bonus'];
        String totalVal = data['total'];
        if (int.parse(bonusVal) > 0) {
          return "🎲 出目[$baseVal] + アイテム[$bonusVal] = 【$totalValマス】進みます！";
        } else {
          return "🎲 出目[$baseVal] = 【$totalValマス】進みます！";
        }

      // ★追加: アイテム拾得通知の処理
      case 'ItemPickup':
        String pId = data['playerId'];
        String itemId = data['itemId'];
        
        if (!allPlayerInventories.containsKey(pId)) {
          allPlayerInventories[pId] = {};
        }
        allPlayerInventories[pId]![itemId] = (allPlayerInventories[pId]![itemId] ?? 0) + 1;
        
        return "✨ $pId が $itemId を獲得しました！";

      case 'GameEnd':
        gameStatusMessage = data['result'];
        hasRolledThisTurn = true; 
        return "🏁 ゲーム終了: ${data['result']}";

      default:
        return null;
    }
  }
}