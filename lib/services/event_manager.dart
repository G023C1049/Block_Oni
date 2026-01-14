import 'dart:math';
import '../models/player.dart';
import '../models/item.dart';

class EventManager {
  
  // 天候適用
  void applyWeather(int weatherType, List<Player> players) {
    switch (weatherType) {
      case 1: applyRain(players); break;
      case 2: applyThunder(); break;
      default: break; // 0:晴れ
    }
  }

  // 雨：最上段ワープ（※1 衝突回避付き）
  void applyRain(List<Player> players) {
    for (var p in players) {
      p.position = Vector2Int(p.position.x, 4); // Y=4(最上段)へ
    }
    _resolveCollision(players); // 衝突回避
  }

  // 雷：通行不可
  void applyThunder() {
    // ランダムな1マスを通行不可にする処理
  }

  // アイテム使用
  void useItem(String itemId, Player user, List<Player> allPlayers) {
    // アイテム定義を取得する想定（ここでは仮の判定）
    // 効果に応じてメソッドを呼び出す
    /*
    switch (effectType) {
      case ItemEffectType.AddDiceValue: applyDicePlus(); break;
      case ItemEffectType.DiceFixed: applyDiceFixed(); break;
      case ItemEffectType.DiceRange: applyDiceRange(); break;
      case ItemEffectType.BlockCell: applyBlockTile(); break;
      case ItemEffectType.MovementOverride: applyMovementOverride(); break;
      case ItemEffectType.Teleport: applyTeleport(user, allPlayers); break;
      case ItemEffectType.StageRotate: applyStageRotate(); break;
    }
    */
    
    // 所持数減算
    if (user.inventory.containsKey(itemId)) {
       user.inventory[itemId] = (user.inventory[itemId] ?? 1) - 1;
    }
  }

  // --- 各アイテム効果メソッド ---

  void applyDicePlus() { /* ダイス目加算 */ }
  void applyDiceFixed() { /* ダイス目固定 */ }
  void applyDiceRange() { /* ダイス目範囲固定 */ }
  void applyBlockTile() { /* 任意マスを通行不可 */ }
  
  void applyMovementOverride() { 
    // 鬼だけ使用可：3ターン逃走者と同じ動き
  }

  void applyTeleport(Player user, List<Player> allPlayers) {
    var random = Random();
    user.position = Vector2Int(random.nextInt(5), random.nextInt(5));
    _resolveCollision(allPlayers); // ワープ後の衝突回避
  }
  
  void applyStageRotate() { /* ステージ回転 */ }

  // --- 内部ロジック ---

  // ※1 衝突回避ルール
  void _resolveCollision(List<Player> players) {
    var runner = players.firstWhere((p) => p.role == PlayerRole.Runner);
    var onis = players.where((p) => p.role == PlayerRole.Oni);

    for (var oni in onis) {
      if (runner.position == oni.position) {
        // 逃走者をランダムに周囲へ逃がす
        var random = Random();
        runner.position = Vector2Int(
          runner.position.x + (random.nextInt(3) - 1),
          runner.position.y + (random.nextInt(3) - 1)
        );
      }
    }
  }
}