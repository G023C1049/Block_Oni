import 'package:flutter/material.dart';
import '../main.dart';

class GlobalOverlay {
  static final GlobalOverlay _instance = GlobalOverlay._internal();
  factory GlobalOverlay() => _instance;
  GlobalOverlay._internal();

  OverlayEntry? _entry;

  void show({required Widget child}) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: hide,
              child: Container(color: Colors.black54),
            ),
          ),
          Center(child: child),
        ],
      ),
    );

    navigatorKey.currentState!.overlay!.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
