import 'package:flutter/material.dart';
import '../models/game_types.dart'; // WinState用
import '../models/player.dart';     // PlayerRole用

class ResultScreen extends StatelessWidget {
  final WinState winState;       // 全体の勝敗結果
  final PlayerRole myRole;       // 自分の役割 (player.dartの定義を使用)
  final VoidCallback onReturnToLobby; // ロビーに戻る時の処理

  const ResultScreen({
    super.key, // warning修正: use_super_parameters
    required this.winState,
    required this.myRole,
    required this.onReturnToLobby,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 自分が勝ったかどうかを判定する
    bool isWinner = false;
    if (winState == WinState.OniWin && myRole == PlayerRole.Oni) {
      isWinner = true; // 鬼が勝って、自分も鬼なら勝ち
    } else if (winState == WinState.RunnerWin && myRole == PlayerRole.Runner) {
      isWinner = true; // 逃走者が勝って、自分も逃走者なら勝ち
    }

    // 2. 勝敗に応じて表示する画像を決める
    final String imagePath = isWinner
        ? "assets/images/youwin.jpeg"  // 勝った時の画像パス
        : "assets/images/lose.png";    // 負けた時の画像パス

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: onReturnToLobby,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 勝敗画像
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // 画像がない場合のエラー表示
                    return Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: Text(
                        isWinner ? "YOU WIN!" : "YOU LOSE...",
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black54
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ロビーに戻るボタン
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: ElevatedButton(
                onPressed: onReturnToLobby,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                ),
                child: const Text("ロビーへ戻る", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}