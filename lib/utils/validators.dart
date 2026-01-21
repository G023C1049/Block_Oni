class Validators {
  static bool isValidUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 12) return false;

    // 絵文字を弾く（サロゲートペア検出）
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1FAFF}]',
      unicode: true,
    );
    if (emojiRegex.hasMatch(trimmed)) return false;

    return true;
  }

  static bool isValidPassword(String password) {
    return password.length >= 4 && password.length <= 8;
  }

  static bool isValidChat(String text) {
    return text.length <= 140;
  }
}
