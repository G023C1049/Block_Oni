import 'package:flutter/material.dart';

// Groupモデル定義
class Group {
  final String id;
  final String name;
  final String? password;
  List<String> members;
  // chatHistoryを削除しました

  Group({
    required this.id,
    required this.name,
    this.password,
    required this.members,
  });
}

class GroupProvider with ChangeNotifier {
  final List<Group> _groups = [];
  Group? _currentGroup;

  Group? get currentGroup => _currentGroup;
  List<Group> get allGroups => _groups;

  // 1. 新規グループ作成
  Future<String> createGroup(String groupName, String? password, String playerName) async {
    // ID生成（簡易的にタイムスタンプなどを使用）
    final String newId = (1000 + _groups.length).toString();
    
    final newGroup = Group(
      id: newId,
      name: groupName,
      password: password,
      members: [playerName], // 作成者を最初のメンバーに追加
    );

    _groups.add(newGroup);
    _currentGroup = newGroup;
    notifyListeners();
    return newId;
  }

  // 2. グループ参加
  Future<bool> joinGroup(String groupId, String? inputPass, String playerName) async {
    try {
      // IDで検索
      final group = _groups.firstWhere((g) => g.id == groupId);

      // チェック処理
      if (group.members.length >= 4) return false; // 満員
      if (group.password != null && group.password!.isNotEmpty) {
         if (group.password != inputPass) return false; // パス不一致
      }

      // メンバー追加
      group.members.add(playerName);
      _currentGroup = group;
      notifyListeners();
      return true;
    } catch (e) {
      // 見つからない場合など
      return false;
    }
  }

  // 3. グループ退出
  void leaveGroup(String playerName) {
    if (_currentGroup != null) {
      _currentGroup!.members.remove(playerName);
      if (_currentGroup!.members.isEmpty) {
        _groups.remove(_currentGroup);
      }
      _currentGroup = null;
      notifyListeners();
    }
  }
}