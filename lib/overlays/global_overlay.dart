import 'package:flutter/material.dart';
import '../main.dart'; // navigatorKeyを使用するため

class GlobalOverlay {
  static final GlobalOverlay _instance = GlobalOverlay._internal();
  factory GlobalOverlay() => _instance;
  GlobalOverlay._internal();

  OverlayEntry? _entry;

  void show({required Widget child}) {
    if (_entry != null) return; // 既に表示中なら何もしない

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 背景タップで閉じるための透明レイヤー
          Positioned.fill(
            child: GestureDetector(
              onTap: hide,
              child: Container(color: Colors.black54),
            ),
          ),
          // コンテンツ
          Center(child: child),
        ],
      ),
    );

    overlayState.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}