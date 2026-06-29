import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/env/app_env.dart';
import '../core/http/dio_factory.dart';
import '../core/realtime/notificacoes_socket.dart';
import '../core/storage/token_storage.dart';

/// Storage seguro (Keystore no Android, IndexedDB criptografado na Web).
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'lamd_secure_storage'),
  ),
);

/// Persistência do token de acesso.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

/// Callback executado quando o backend retorna 401.
///
/// O callback é configurado em `main.dart` (após a árvore de providers ser
/// inicializada) para acionar `AuthController.logout()`.
class UnauthorizedHandler extends Notifier<Future<void> Function()> {
  @override
  Future<void> Function() build() => () async {};

  void set(Future<void> Function() handler) {
    state = handler;
  }
}

final unauthorizedHandlerProvider =
    NotifierProvider<UnauthorizedHandler, Future<void> Function()>(
      UnauthorizedHandler.new,
    );

Dio _makeClient(Ref ref, String baseUrl) {
  final storage = ref.watch(tokenStorageProvider);
  return buildDio(
    baseUrl: baseUrl,
    storage: storage,
    onUnauthorized: () async {
      await ref.read(unauthorizedHandlerProvider)();
    },
  );
}

final monolitoClientProvider = Provider<Dio>(
  (ref) => _makeClient(ref, AppEnv.monolitoBaseUrl),
);

final notificacoesClientProvider = Provider<Dio>(
  (ref) => _makeClient(ref, AppEnv.notificacoesBaseUrl),
);

final tarefaClientProvider = Provider<Dio>(
  (ref) => _makeClient(ref, AppEnv.tarefaBaseUrl),
);

final documentoClientProvider = Provider<Dio>(
  (ref) => _makeClient(ref, AppEnv.documentoBaseUrl),
);

/// Socket único compartilhado entre features.
final notificacoesSocketProvider = Provider<NotificacoesSocket>((ref) {
  final socket = NotificacoesSocket(ref.watch(tokenStorageProvider));
  ref.onDispose(socket.dispose);
  return socket;
});
