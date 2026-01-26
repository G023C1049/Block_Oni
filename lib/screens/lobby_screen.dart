import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/lobby_view_model.dart';
import '../providers/user_provider.dart';
import '../screens/settings_overlay.dart'; // 設定画面
import '../overlays/global_overlay.dart'; // Overlay管理

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final lobbyVM = context.watch<LobbyViewModel>();
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      // ★修正1: キーボードが出ても画面（背景）を縮めない設定。これでオーバーフローエラーが消えます。
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('ロビー'),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        actions: [
          // 設定ボタン
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              GlobalOverlay().show(child: const SettingsOverlay());
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 左側：グループ一覧エリア
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('グループ一覧', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // 検索ボックス
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'ID または 部屋名で検索',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      lobbyVM.searchGroup(val, groupProvider.allGroups);
                    },
                  ),
                  const SizedBox(height: 10),

                  // リスト表示
                  Expanded(
                    child: _buildGroupList(groupProvider, lobbyVM, userProvider),
                  ),
                ],
              ),
            ),
          ),

          // 右側：操作エリア
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              // 右パネルも念のためスクロール可能にしておく
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_esports, size: 80, color: Colors.cyan),
                      const SizedBox(height: 20),
                      Text("ようこそ\n${userProvider.username} さん", 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 40), 
                      
                      // 新規作成ボタン
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('グループ作成'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showCreateDialog(context, groupProvider, userProvider),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 戻るボタン
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('戻る'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(GroupProvider groupProvider, LobbyViewModel lobbyVM, UserProvider userProvider) {
    final displayList = _searchCtrl.text.isNotEmpty 
        ? lobbyVM.searchResults 
        : groupProvider.allGroups;

    if (displayList.isEmpty) {
      return const Center(child: Text("グループが見つかりません"));
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final group = displayList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${group.id} / 参加: ${group.members.length}人"),
            trailing: ElevatedButton(
              child: const Text("参加"),
              onPressed: () async {
                String? inputPass;
                if (group.password != null && group.password!.isNotEmpty) {
                  inputPass = await _showPasswordInputDialog(context);
                  if (inputPass == null) return;
                }

                if (!mounted) return;
                bool success = await groupProvider.joinGroup(group.id, inputPass, userProvider.username);
                
                if (success && mounted) {
                   Navigator.pushNamed(context, '/waiting');
                } else if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("参加できませんでした")),
                   );
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, GroupProvider groupProvider, UserProvider userProvider) {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新規グループ作成'),
        
        // ★修正2: ここを true にするだけで、キーボードが出ても自動でスクロールして表示されます
        scrollable: true,

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl, 
              decoration: const InputDecoration(labelText: 'グループ名'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl, 
              decoration: const InputDecoration(labelText: 'パスワード(任意)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              await groupProvider.createGroup(nameCtrl.text, passCtrl.text, userProvider.username);
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/waiting');
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPasswordInputDialog(BuildContext context) async {
    String? result;
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワード入力'),
        // ★修正3: こちらも scrollable: true に設定
        scrollable: true,
        content: TextField(
          controller: ctrl, 
          obscureText: true, 
          decoration: const InputDecoration(hintText: 'パスワードを入力'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () { result = ctrl.text; Navigator.pop(context); }, 
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }
}