import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/lobby_view_model.dart';
import 'waiting_room_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final lobbyVM = Provider.of<LobbyViewModel>(context);
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () {}),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Row(
        children: [
          // 左側：グループ一覧エリア
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('グループ一覧', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '検索',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: const Icon(Icons.refresh),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) => lobbyVM.searchGroup(val, groupProvider.allGroups),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lobbyVM.searchResults.isEmpty ? groupProvider.allGroups.length : lobbyVM.searchResults.length,
                      itemBuilder: (context, index) {
                        final g = lobbyVM.searchResults.isEmpty ? groupProvider.allGroups[index] : lobbyVM.searchResults[index];
                        return Card(
                          child: ListTile(
                            title: Text(g.name),
                            subtitle: Text('ID: ${g.id}'),
                            // パスワードがある場合は鍵アイコンを表示
                            leading: g.password != null && g.password!.isNotEmpty 
                                ? const Icon(Icons.lock, color: Colors.orange) 
                                : const Icon(Icons.lock_open, color: Colors.green),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                // 修正ポイント：パスワードが必要な場合は入力ダイアログを出す
                                String? enteredPass;
                                if (g.password != null && g.password!.isNotEmpty) {
                                  enteredPass = await _showPasswordInputDialog(context);
                                  if (enteredPass == null) return; // キャンセルされたら何もしない
                                }

                                bool ok = await groupProvider.joinGroup(g.id, enteredPass);
                                if (!context.mounted) return;

                                if (ok) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WaitingRoomScreen()));
                                } else {
                                  // 修正ポイント：失敗した時にメッセージを出す
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('入室に失敗しました（パスワードが違うか、満員です）')),
                                  );
                                }
                              },
                              child: const Text('参加'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右側：グループ作成エリア
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('グループ作成', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  const Text('グループ名'),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(filled: true, fillColor: Colors.white10)),
                  const SizedBox(height: 20),
                  const Text('ルームパスワード'),
                  TextField(controller: passCtrl, decoration: const InputDecoration(filled: true, fillColor: Colors.white10, hintText: '空欄でもOK')),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        backgroundColor: Colors.grey[300],
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('グループ名を入力してください')));
                          return;
                        }
                        await groupProvider.createGroup(nameCtrl.text, passCtrl.text);
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WaitingRoomScreen()));
                      },
                      child: const Text('作成', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                      child: const Text('戻る', style: TextStyle(color: Colors.black)),
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

  // 参加時にパスワードを入力してもらうためのダイアログ
  Future<String?> _showPasswordInputDialog(BuildContext context) async {
    String? result;
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワード入力'),
        content: TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(hintText: 'パスワードを入力')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () { result = ctrl.text; Navigator.pop(context); }, child: const Text('OK')),
        ],
      ),
    );
    return result;
  }
}