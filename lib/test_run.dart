import 'models/player.dart';
import 'models/item.dart';
import 'providers/game_rule_manager.dart';
import 'services/event_manager.dart';

// プログラムのスタート地点
void main() {
  print("=== テスト開始: 奥山担当ロジック ===");

  // 1. 準備: マネージャーとプレイヤーを用意
  final ruleManager = GameRuleManager();
  final eventManager = EventManager();

  // 逃走者 (座標 0, 0)
  Player runner = Player(
    playerId: 1, 
    role: PlayerRole.Runner, 
    position: Vector2Int(0, 0)
  );

  // 鬼 (座標 2, 2)
  Player oni = Player(
    playerId: 2, 
    role: PlayerRole.Oni, 
    position: Vector2Int(2, 2)
  );

  List<Player> allPlayers = [runner, oni];

  // --- 実験A: 勝敗判定のテスト ---
  print("\n--- 実験A: 勝敗判定 ---");
  
  // まだ捕まっていない状態
  var result1 = ruleManager.checkWinCondition([oni.position], runner.position, 1);
  print("1. 離れている時: $result1 (期待値: WinState.None)");

  // 鬼を逃走者と同じ場所に移動させてみる
  print(">> 鬼を逃走者の位置(0, 0)に移動させます...");
  oni.position = Vector2Int(0, 0);

  // 捕まったか判定
  var result2 = ruleManager.checkWinCondition([oni.position], runner.position, 1);
  print("2. 重なった時: $result2 (期待値: WinState.OniWin)");


  // --- 実験B: イベント（雨）と衝突回避のテスト ---
  print("\n--- 実験B: 雨イベントと衝突回避 ---");
  
  // 位置をリセット
  runner.position = Vector2Int(1, 0);
  oni.position = Vector2Int(1, 0); // わざと最初から重ねておく
  
  print("雨が降る前の位置 -> 逃走者:(${runner.position.x}, ${runner.position.y}) / 鬼:(${oni.position.x}, ${oni.position.y})");
  
  print(">> 雨イベントを実行します（全員 Y=4 にワープ）...");
  eventManager.applyWeather(1, allPlayers);

  print("雨が降った後の位置 -> 逃走者:(${runner.position.x}, ${runner.position.y}) / 鬼:(${oni.position.x}, ${oni.position.y})");

  if (runner.position != oni.position) {
    print("★成功！: 衝突回避ルールが発動し、逃走者が逃げました！");
  } else {
    print("★失敗...: 重なったままです");
  }

  print("\n=== テスト終了 ===");
}