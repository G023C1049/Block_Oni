import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/validators.dart';

void main() {
  test('A-E-06 パスワード制約', () {
    expect(Validators.isValidPassword('123'), false);
    expect(Validators.isValidPassword('1234'), true);
  });

  test('A-E-07 チャット文字数', () {
    expect(Validators.isValidChat('a' * 140), true);
    expect(Validators.isValidChat('a' * 141), false);
  });
}
