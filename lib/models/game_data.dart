// プレイヤーの状態を管理するクラス
class Player {
  final int playerId; // プレイヤー識別子
  final String role; // "Oni" または "Runner"
  int posX = 0; // 現在位置 X
  int posY = 0; // 現在位置 Y
  bool hasActedThisTurn = false; // 当ターン行動済みか
  Map<String, int> inventory = {}; // アイテム所持数 <ID, 個数>

  Player({required this.playerId, required this.role});
}

// アイテムの基本情報を定義するクラス
class ItemDefinition {
  final String itemId;
  final String itemName;
  final String effectType; // 効果種別
  final bool isUsableByRunner;
  final int maxStack = 5; // 最大所持数は5個

  ItemDefinition({
    required this.itemId, 
    required this.itemName, 
    required this.effectType, 
    required this.isUsableByRunner
  });
}