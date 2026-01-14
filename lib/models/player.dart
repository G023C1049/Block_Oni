// 座標管理用クラス (Vector2Int)
class Vector2Int {
  int x, y;
  Vector2Int(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2Int && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

// 役割定義
enum PlayerRole { Oni, Runner }

// プレイヤー定義
class Player {
  final int playerId;
  final PlayerRole role;
  Vector2Int position;
  bool hasActedThisTurn = false;
  Map<String, int> inventory = {}; // <itemId, 所持数>

  // 鬼の進行方向（LockOniDirection用）
  Vector2Int? lockedDirection; 

  Player({
    required this.playerId,
    required this.role,
    required this.position,
  });
}