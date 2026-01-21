import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// 責務: Socket.ioの接続管理、イベント送受信のラップ [cite: 43-44]
class SocketService {
  // シングルトンパターン（アプリ内で1つだけインスタンスを作る）
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  /// ソケット接続の確立 [cite: 45]
  void init(String url) {
    _socket = io.io(url, io.OptionBuilder()
      .setTransports(['websocket']) // WebSocketのみ使用
      .disableAutoConnect()
      .build());

    _socket?.onConnect((_) => print('Connected to Server'));
    _socket?.onDisconnect((_) => print('Disconnected from Server'));
    _socket?.onConnectError((data) => print('Connect Error: $data'));
    
    _socket?.connect();
  }

  /// サーバーへイベント送信し、応答(Ack)を待機する [cite: 45]
  Future<dynamic> emitWithAck(String event, dynamic data) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket is not connected');
    }

    final completer = Completer<dynamic>();

    // サーバーへ送信
    _socket!.emitWithAck(event, data, ack: (response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    // 5秒でタイムアウト [cite: 46]
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Server response timed out: $event'),
    );
  }

  // Ackを待たない通常の送信
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  // イベント受信リスナーの登録
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }
}