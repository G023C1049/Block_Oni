import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/user_provider.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final userProvider = context.read<UserProvider>();
    final group = groupProvider.currentGroup;

    // もしデータが空ならエラー表示（通常ありえないが念のため）
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: const Center(child: Text('グループが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('待機室: ${group.name} (ID: ${group.id})'),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 退出処理
            groupProvider.leaveGroup(userProvider.username);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "参加メンバー",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          // メンバーリスト表示
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final memberName = group.members[index];
                final isMe = memberName == userProvider.username;
                
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      memberName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        color: isMe ? Colors.cyan : Colors.black,
                      ),
                    ),
                    trailing: index == 0 ? const Chip(label: Text("ホスト")) : null,
                  ),
                );
              },
            ),
          ),

          // ゲーム開始ボタンエリア
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // ゲーム画面へ遷移
                  Navigator.pushNamed(context, '/game');
                },
                child: const Text(
                  "ゲーム開始！",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}