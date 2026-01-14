// 効果種別の定義
enum ItemEffectType {
  AddDiceValue,      // ダイス目加算
  BlockCell,         // マス通行不可
  DiceFixed,         // ダイス目固定
  DiceRange,         // ダイス目範囲固定
  MovementOverride,  // 鬼の移動制限解除
  Teleport,          // テレポート
  StageRotate        // ステージ回転
}

// アイテム定義クラス
class Item {
  final String itemId;
  final String itemName;
  final ItemEffectType effectType;
  final bool isUsableByRunner;
  final String description;
  final int maxStack = 5; // 最大所持数

  Item({
    required this.itemId,
    required this.itemName,
    required this.effectType,
    required this.isUsableByRunner,
    required this.description,
  });
}