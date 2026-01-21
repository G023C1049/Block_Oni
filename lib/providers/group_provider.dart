import 'package:flutter/material.dart';

class Group {
  final String id;
  final String name;
  final String? password;
  List<String> members;
  List<Map<String, String>> chatHistory;

  Group({required this.id, required this.name, this.password, required this.members, required this.chatHistory});
}

class GroupProvider with ChangeNotifier {
  final List<Group> _groups = [];
  Group? _currentGroup;

  Group? get currentGroup => _currentGroup;
  List<Group> get allGroups => _groups;

  // 1. 新規グループ作成
  Future<String> createGroup(String groupName, String? password) async {
    final String newId = (100 + _groups.length).toString();
    final newGroup = Group(
      id: newId,
      name: groupName,
      password: password,
      members: ['自分'], 
      chatHistory: [],
    );
    _groups.add(newGroup);
    _currentGroup = newGroup;
    notifyListeners();
    return newId;
  }

  // 2. グループ参加
  Future<bool> joinGroup(String groupId, String? inputPass) async {
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      if (group.members.length >= 4) return false; // 満員
      if (group.password != null && group.password != inputPass) return false; // パス不一致

      group.members.add('プレイヤー ${group.members.length + 1}');
      _currentGroup = group;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 3. チャットメッセージ送信
  Future<void> sendChatMessage(String message, String groupId) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    group.chatHistory.add({
      'sender': '自分',
      'message': message,
      'time': DateTime.now().toString().substring(11, 16),
    });
    notifyListeners();
  }
}