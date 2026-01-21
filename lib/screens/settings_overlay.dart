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

            const SizedBox(height: 12),
            const Text('画質', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['低', '中', '高'].map((q) {
                return ChoiceChip(
                  label: Text(q),
                  selected: userProv.quality == q,
                  onSelected: (_) {
                    userProv.updateSettings(quality: q);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('サウンド'),
              value: userProv.soundEnabled,
              onChanged: (v) =>
                  userProv.updateSettings(soundEnabled: v),
            ),

            SwitchListTile(
              title: const Text('ボイスチャット'),
              value: userProv.vcEnabled,
              onChanged: (v) =>
                  userProv.updateSettings(vcEnabled: v),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => GlobalOverlay().hide(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
