import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/documento_repository.dart';
import '../domain/documento.dart';

final documentoRepositoryProvider = Provider<DocumentoRepository>((ref) {
  return DocumentoRepository(ref.watch(documentoClientProvider));
});

/// Lista reativa de documentos — reagindo a eventos `documento.*` via WebSocket.
final documentosProvider = FutureProvider.autoDispose
    .family<List<Documento>, String?>((ref, associacaoId) {
      // Re-busca automaticamente ao trocar de conta.
      final userId = ref.watch(authUserIdProvider);
      if (userId == null) return Future.value(const <Documento>[]);
      final socket = ref.watch(notificacoesSocketProvider);
      final sub = socket.onNovaNotificacao.listen((event) {
        final tipo = event['tipo'];
        if (tipo is String && tipo.startsWith('documento.')) {
          ref.invalidateSelf();
        }
      });
      ref.onDispose(sub.cancel);
      return ref
          .read(documentoRepositoryProvider)
          .listar(associacaoId: associacaoId);
    });
