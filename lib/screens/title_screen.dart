import 'package:flutter/material.dart';
// GameScreenをインポートします
import 'game_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイトルロゴやテキスト
              const Icon(
                Icons.extension,
                size: 100,
                color: Colors.cyan,
              ),
              const SizedBox(height: 20),
              const Text(
                'Block Oni',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ブロックおに',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),

              // ゲームスタートボタン
              GestureDetector(
                onTap: () {
                  // スナックバーを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ゲームを開始します...')),
                  );

                  // ゲーム画面へ遷移
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GameScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.shade400,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text(
                        "GAME START",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}