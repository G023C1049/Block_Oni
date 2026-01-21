import 'package:flutter_test/flutter_test.dart';
import '../lib/services/socket_service.dart';

void main() {
  test('A-E-05 Socket未接続', () async {
    final service = SocketService();

    expect(
      () async => await service.emitWithAck('test', {}),
      throwsException,
    );
  });
}
