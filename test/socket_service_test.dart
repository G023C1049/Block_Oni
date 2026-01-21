import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/socket_service.dart';

void main() {
  test('A-E-05 タイムアウト', () async {
    final socket = SocketService();

    expect(
      () => socket.emitWithAck('event', {}),
      throwsA(isA<Exception>()),
    );
  });
}
