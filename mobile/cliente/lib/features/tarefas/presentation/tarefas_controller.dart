import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/tarefa_repository.dart';
import '../domain/tarefa.dart';

final tarefaRepositoryProvider = Provider<TarefaRepository>((ref) {
  return TarefaRepository(ref.watch(tarefaClientProvider));
});

class TarefasListArgs {
  const TarefasListArgs({this.associacaoId, this.imovelId});
  final String? associacaoId;
  final String? imovelId;

  @override
  bool operator ==(Object other) =>
      other is TarefasListArgs &&
      other.associacaoId == associacaoId &&
      other.imovelId == imovelId;

  @override
  int get hashCode => Object.hash(associacaoId, imovelId);
}

/// Lista reativa de tarefas — reagindo a eventos `tarefa.*` via WebSocket.
final tarefasProvider = FutureProvider.autoDispose
    .family<List<Tarefa>, TarefasListArgs>((ref, args) {
      // Re-busca automaticamente ao trocar de conta.
      final userId = ref.watch(authUserIdProvider);
      if (userId == null) return Future.value(const <Tarefa>[]);
      final socket = ref.watch(notificacoesSocketProvider);
      final sub = socket.onNovaNotificacao.listen((event) {
        final tipo = event['tipo'];
        if (tipo is String && tipo.startsWith('tarefa.')) {
          ref.invalidateSelf();
        }
      });
      ref.onDispose(sub.cancel);
      return ref
          .read(tarefaRepositoryProvider)
          .listar(associacaoId: args.associacaoId, imovelId: args.imovelId);
    });
