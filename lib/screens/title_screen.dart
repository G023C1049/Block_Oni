import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // navigatorKeyへのアクセスのため
import '../providers/user_provider.dart';

/* ===============================
  [cite_start]タイトル画面 [cite: 20]
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
    // 画面描画完了後にProviderから保存済みの名前を取得してセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameController.text = context.read<UserProvider>().username;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /* ===== メインコンテンツエリア ===== */
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // タイトルロゴ等
                    const Text(
                      'ブロックおに',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 60),

                    /* ===== ユーザー名入力フォーム ===== */
                    Container(
                      width: 320,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ユーザー名 (1~12文字)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  maxLength: 12, // UI上の文字数制限
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    counterText: "", // カウンター非表示
                                    hintText: '名前を入力',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  // Providerを通じて保存処理を実行 [cite: 51]
                                  final success = await context
                                      .read<UserProvider>()
                                      .saveUsername(_nameController.text);
                                  
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success 
                                        ? 'ユーザー名を保存しました' 
                                        : 'エラー: 1~12文字で入力してください'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                                child: const Text('決定'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    /* ===== ゲーム開始エリア ===== */
                    GestureDetector(
                      onTap: () {
                        // TODO: バリデーションチェック後にロビー画面へ遷移
                        // Navigator.pushNamed(context, '/lobby');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ロビーへ接続します...')),
                        );
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            size: 80,
                            color: Colors.orangeAccent.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'GAME START',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /* ===== 設定ボタン (右上に配置) ===== */
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                child: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () {
                  // オーバーレイを表示
                  GlobalOverlay().show(
                    child: const SettingsOverlay(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===============================
  GlobalOverlay管理クラス
  責務: 画面遷移に依存せず最前面にOverlayを表示する
================================ */
class GlobalOverlay {
  static final GlobalOverlay _instance = GlobalOverlay._internal();
  factory GlobalOverlay() => _instance;
  GlobalOverlay._internal();

  OverlayEntry? _entry;

  void show({required Widget child}) {
    if (_entry != null) return; // 既に表示中なら無視

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 背景タップで閉じるための透明なレイヤー
          Positioned.fill(
            child: GestureDetector(
              onTap: hide,
              child: Container(color: Colors.black54),
            ),
          ),
          // コンテンツ
          Center(child: child),
        ],
      ),
    );

    // main.dartで定義したnavigatorKeyを使用して挿入
    navigatorKey.currentState!.overlay!.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

/* ===============================
  設定画面コンポーネント
  UserProviderと連携して設定変更を即時反映する
================================ */
class SettingsOverlay extends StatelessWidget {
  const SettingsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // watchを使用して値の変更を監視し、UIを再描画する
    final userProv = context.watch<UserProvider>();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '設定',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => GlobalOverlay().hide(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // 画質設定
            const Text('画質設定', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['低', '中', '高'].map((label) {
                final isSelected = userProv.quality == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: Colors.cyanAccent,
                  onSelected: (selected) {
                    if (selected) {
                      userProv.updateSettings(quality: label);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // サウンド設定
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('サウンド (BGM/SE)', style: TextStyle(fontWeight: FontWeight.bold)),
              value: userProv.soundEnabled,
              activeColor: Colors.cyan,
              onChanged: (v) => userProv.updateSettings(soundEnabled: v),
            ),

            // ボイスチャット設定
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ボイスチャット', style: TextStyle(fontWeight: FontWeight.bold)),
              value: userProv.vcEnabled,
              activeColor: Colors.cyan,
              onChanged: (v) => userProv.updateSettings(vcEnabled: v),
            ),

            const SizedBox(height: 16),
            
            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => GlobalOverlay().hide(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}