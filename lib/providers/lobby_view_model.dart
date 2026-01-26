import 'package:flutter/material.dart';
import 'group_provider.dart';

class LobbyViewModel with ChangeNotifier {
  List<Group> _searchResults = [];
  List<Group> get searchResults => _searchResults;

  // 1. グループ検索 (IDの部分一致)
  void searchGroup(String keyword, List<Group> allGroups) {
    if (keyword.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = allGroups
          .where((g) => g.id.contains(keyword) || g.name.contains(keyword))
          .toList();
    }
    notifyListeners();
  }
}