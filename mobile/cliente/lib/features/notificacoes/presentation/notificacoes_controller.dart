import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/notificacao_repository.dart';
import '../domain/notificacao.dart';

final notificacaoRepositoryProvider = Provider<NotificacaoRepository>((ref) {
  return NotificacaoRepository(ref.watch(notificacoesClientProvider));
});

/// Listagem reativa. Quando uma nova notificação chega via WebSocket,
/// invalida automaticamente este provider.
class NotificacoesController extends AsyncNotifier<NotificacoesListResult> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  Future<NotificacoesListResult> build() async {
    final socket = ref.watch(notificacoesSocketProvider);
    _sub = socket.onNovaNotificacao.listen((_) => refresh());
    ref.onDispose(() => _sub?.cancel());
    return ref.read(notificacaoRepositoryProvider).listar();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificacaoRepositoryProvider).listar(),
    );
  }

  Future<void> marcarTodasComoLidas() async {
    await ref.read(notificacaoRepositoryProvider).marcarTodasComoLidas();
    await refresh();
  }

  Future<void> marcarComoLida(String id) async {
    await ref.read(notificacaoRepositoryProvider).marcarComoLida(id);
    await refresh();
  }
}

final notificacoesControllerProvider =
    AsyncNotifierProvider<NotificacoesController, NotificacoesListResult>(
      NotificacoesController.new,
    );
