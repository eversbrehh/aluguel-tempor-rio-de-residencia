import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../env/app_env.dart';
import '../storage/token_storage.dart';

/// Gateway de WebSocket (Socket.IO) com o MS Notificações.
///
/// Reconecta automaticamente e expõe um `Stream<Map>` com os payloads de
/// `notificacao:nova`.
class NotificacoesSocket {
  NotificacoesSocket(this._storage);

  final TokenStorage _storage;

  io.Socket? _socket;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get onNovaNotificacao => _controller.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return;

    _socket?.dispose();
    final socket = io.io(
      AppEnv.notificacoesWsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {});
    socket.on('notificacao:nova', (data) {
      if (data is Map) {
        _controller.add(Map<String, dynamic>.from(data));
      }
    });
    socket.connect();
    _socket = socket;
  }

  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _socket?.dispose();
    _controller.close();
  }
}
