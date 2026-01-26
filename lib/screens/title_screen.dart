import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../overlays/global_overlay.dart'; // 設定画面表示用
import '../screens/settings_overlay.dart'; // 設定画面の中身

/* ===============================
  タイトル画面
================================ */
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 画面描画後に保存された名前をセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      _nameController.text = userProvider.username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Stackを使って右上に設定ボタンを配置できるようにする
      body: SafeArea(
        child: Stack(
          children: [
            // --- メインコンテンツ ---
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // タイトルロゴ
                    const Icon(Icons.directions_run, size: 100, color: Colors.cyan),
                    const SizedBox(height: 20),
                    const Text(
                      'ブロックおに',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.cyan),
                    ),
                    const SizedBox(height: 40),

                    // 名前入力
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'プレイヤー名',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // スタートボタン
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final name = _nameController.text;
                          if (name.isEmpty) return;

                          // 名前を保存
                          final success = await context.read<UserProvider>().saveUsername(name);
                          
                          if (success && mounted) {
                            Navigator.pushNamed(context, '/lobby');
                          }
                        },
                        child: const Text('スタート', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- ★追加: 設定ボタン（右上） ---
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.settings, size: 30, color: Colors.grey),
                onPressed: () {
                  // 設定オーバーレイを表示
                  GlobalOverlay().show(child: const SettingsOverlay());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}