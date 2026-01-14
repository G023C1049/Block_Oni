import '../models/player.dart';
import '../models/item.dart';

enum WinState { None, OniWin, RunnerWin }

class GameRuleManager {
  int currentTurn = 1;
  double remainingTime = 30.0;
  bool stageRotateFlag = false;

  // ゲーム開始処理
  void startGame() {
    currentTurn = 1;
    remainingTime = 30.0;
    stageRotateFlag = false;
    // 役割割り当てや初期配置のロジックをここに記述
  }

  // ゲーム終了処理
  void endGame(WinState result) {
    // タイマー停止、リザルト画面への更新処理など
    print("Game End: $result");
  }

  // 移動可能方向の判定
  List<Vector2Int> getAvailableMoveDirections(Player player) {
    List<Vector2Int> directions = [
      Vector2Int(0, 1), Vector2Int(0, -1), Vector2Int(1, 0), Vector2Int(-1, 0)
    ];

    // 逃走者は全方向移動可能
    if (player.role == PlayerRole.Runner) {
      return directions;
    } 
    // 鬼は固定された進行方向のみ（初回移動後）
    else if (player.lockedDirection != null) {
      return [player.lockedDirection!];
    }
    
    return directions; // 鬼の初回は全方向可
  }

  // 鬼の進行方向固定
  void lockOniDirection(Player player, Vector2Int direction) {
    if (player.role == PlayerRole.Oni && player.lockedDirection == null) {
      player.lockedDirection = direction;
    }
  }

  // タイマー開始
  void startTurnTimer(int turnTimeLimit) {
    remainingTime = turnTimeLimit.toDouble();
  }

  // タイマー更新
  double updateTurnTimer(double deltaTime) {
    remainingTime -= deltaTime;
    return remainingTime;
  }

  // タイムアップ判定
  bool isTimeUp() {
    return remainingTime <= 0;
  }

  // タイムアウト時の処理
  void onTurnTimeout(Player player) {
    player.hasActedThisTurn = true;
  }

  // アイテム取得
  void addItem(Player player, String itemId) {
    // 所持数を+1する
    player.inventory[itemId] = (player.inventory[itemId] ?? 0) + 1;
    
    // 上限チェック (MaxStack = 5)
    if (player.inventory[itemId]! > 5) {
      player.inventory[itemId] = 5;
    }
  }

  // 勝敗判定
  WinState checkWinCondition(List<Vector2Int> oniPositions, Vector2Int runnerPos, int turnCount) {
    for (var oniPos in oniPositions) {
      if (oniPos == runnerPos) return WinState.OniWin;
    }
    if (turnCount >= 10) return WinState.RunnerWin;
    
    return WinState.None;
  }

  // ターン進行
  void advanceTurn(List<Player> players) {
    // 全員行動済みならターンを進める
    if (players.every((p) => p.hasActedThisTurn)) {
      currentTurn++;
      for (var p in players) p.hasActedThisTurn = false;
      
      // 4の倍数ターンでステージ回転
      if (currentTurn % 4 == 0) {
        stageRotateFlag = true;
      }
    }
  }

  // リザルト表示
  void showResult(WinState state) {
    if (state != WinState.None) {
      // リザルト画面表示処理
    }
  }

  // ロビーへ戻る
  void returnToLobby() {
    // ロビー遷移処理
  }
}