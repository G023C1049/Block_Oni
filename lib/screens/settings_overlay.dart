import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../overlays/global_overlay.dart';

class SettingsOverlay extends StatelessWidget {
  const SettingsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 320,
          // 画面の高さ80%を上限とし、それ以上はスクロールさせる設定
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // ★修正点: ClipRRectとSingleChildScrollViewでラップしてOverflowを防止
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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

                  const SizedBox(height: 24),
                  
                  // 閉じるボタン
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => GlobalOverlay().hide(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('閉じる', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}