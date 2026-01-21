import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';

// クラス名が「WaitingRoomScreen」であることを確認！
class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool isChatOpen = false;
  final chatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final group = groupProvider.currentGroup;

    // もしデータが空ならエラー表示
    if (group == null) {
      return const Scaffold(body: Center(child: Text('グループが見つかりません')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('待機室: ${group.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // 待機画面のメインレイアウト
          Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    bool hasUser = index < group.members.length;
                    return CircleAvatar(
                      backgroundColor: hasUser ? Colors.blue : Colors.grey[300],
                      child: Icon(Icons.person, size: 50, color: hasUser ? Colors.white : Colors.grey),
                    );
                  },
                ),
              ),
              // 下部の操作ボタン
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // チャットを開くボタン
                    IconButton(
                      icon: const Icon(Icons.list_alt, size: 40),
                      onPressed: () => setState(() => isChatOpen = !isChatOpen),
                    ),
                    const SizedBox(width: 20),
                    // プレイボタン
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('play', style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // チャットのオーバーレイ表示（右側）
          if (isChatOpen)
            Positioned(
              right: 0, top: 0, bottom: 0,
              width: 300,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 16,
                child: Column(
                  children: [
                    AppBar(
                      title: const Text('チャット'),
                      leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => isChatOpen = false)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: group.chatHistory.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            title: Text(group.chatHistory[i]['message']!),
                            subtitle: Text(group.chatHistory[i]['time']!),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatController,
                              decoration: const InputDecoration(hintText: 'メッセージ...'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              if (chatController.text.isNotEmpty) {
                                groupProvider.sendChatMessage(chatController.text, group.id);
                                chatController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}