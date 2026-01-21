// Unityと合わせるため Vector2Int を廃止し、ID文字列ベースに変更
class Player {
  final String playerId;
  final String role; // "Oni" or "Runner"
  
  // UnityのマスID (例: "Top_2_2")
  String currentSquareId = "";
  
  bool hasActedThisTurn = false;
  Map<String, int> inventory = {};
  
  // アイテム効果などで使うパラメータ
  int diceBonus = 0;

  Player({
    required this.playerId,
    required this.role,
    this.currentSquareId = "",
  });

  // JSONなどから生成する場合のファクトリなどがあればここに追加
}

class ItemDefinition {
  final String itemId;
  final String itemName;
  final String effectType; // "Teleport", "StageRotate", etc.
  final bool isUsableByRunner;
  final int maxStack = 5;

  ItemDefinition({
    required this.itemId,
    required this.itemName,
    required this.effectType,
    required this.isUsableByRunner
  });
}