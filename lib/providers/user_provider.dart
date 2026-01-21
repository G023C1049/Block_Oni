import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unity_bridge_service.dart';

/// 担当: ユーザー情報・設定管理クラス
/// 責務: データの永続化と Unity への同期
class UserProvider extends ChangeNotifier {
  final UnityBridgeService _unityBridge;
  final SharedPreferences _prefs; // 外部から注入されるインスタンス

  // ユーザー状態
  String _username = '';

  // 設定状態
  String _quality = '中';
  bool _soundEnabled = true;
  bool _vcEnabled = true;

  // コンストラクタで UnityBridge と SharedPreferences の両方を受け取る
  UserProvider(this._unityBridge, this._prefs) {
    _loadSettings();
  }

  // ゲッター
  String get username => _username;
  String get quality => _quality;
  bool get soundEnabled => _soundEnabled;
  bool get vcEnabled => _vcEnabled;

  /// 初期化時にインスタンス化済みの _prefs から設定を読み込む
  void _loadSettings() {
    _username = _prefs.getString('user_name') ?? '';
    _quality = _prefs.getString('quality') ?? '中';
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _vcEnabled = _prefs.getBool('vc_enabled') ?? true;
    
    // 初期化完了を通知
    notifyListeners();
  }

  /// ユーザー名の保存処理
  /// バリデーション: 1~12文字、空白のみ不可、絵文字不可（簡易チェック）
  Future<bool> saveUsername(String name) async {
    final trimmedName = name.trim();
    
    // バリデーションチェック: 空文字、12文字超過
    if (trimmedName.isEmpty || trimmedName.length > 12) {
      return false; 
    }

    // 絵文字チェック (簡易版: サロゲートペアが含まれるか確認)
    if (trimmedName.runes.any((rune) => rune > 0xFFFF)) {
      return false;
    }

    try {
      // 既に保持している _prefs を使用
      await _prefs.setString('user_name', trimmedName);
      _username = trimmedName;

      // 保存成功後、Unity側に名前情報を送信
      _unityBridge.sendToUnity("UpdatePlayerName", {"name": trimmedName});
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error saving username: $e");
      return false;
    }
  }

  /// 設定の更新処理
  Future<void> updateSettings({
    String? quality,
    bool? soundEnabled,
    bool? vcEnabled,
  }) async {
    if (quality != null) {
      _quality = quality;
      await _prefs.setString('quality', _quality);
    }
    if (soundEnabled != null) {
      _soundEnabled = soundEnabled;
      await _prefs.setBool('sound_enabled', _soundEnabled);
    }
    if (vcEnabled != null) {
      _vcEnabled = vcEnabled;
      await _prefs.setBool('vc_enabled', _vcEnabled);
    }

    // Unity側の設定を更新
    _unityBridge.sendToUnity("UpdateEngineSettings", {
      "quality": _quality,
      "audioVolume": _soundEnabled ? 1.0 : 0.0,
      "vcActive": _vcEnabled,
    });

    notifyListeners();
  }
}