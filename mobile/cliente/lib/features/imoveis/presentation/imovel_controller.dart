import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/imovel_repository.dart';
import '../domain/imovel.dart';

final imovelRepositoryProvider = Provider<ImovelRepository>((ref) {
  return ImovelRepository(ref.watch(monolitoClientProvider));
});

final meusImoveisProvider = FutureProvider.autoDispose<List<Imovel>>((ref) {
  // Re-busca automaticamente ao trocar de conta (login/logout).
  final userId = ref.watch(authUserIdProvider);
  if (userId == null) return Future.value(const <Imovel>[]);
  return ref.watch(imovelRepositoryProvider).listarMeus();
});

final imovelDetalheProvider = FutureProvider.autoDispose.family<Imovel, String>(
  (ref, id) {
    final userId = ref.watch(authUserIdProvider);
    if (userId == null) {
      return Future.error(StateError('Usuário não autenticado'));
    }
    return ref.watch(imovelRepositoryProvider).obter(id);
  },
);

final associacoesDoImovelProvider = FutureProvider.autoDispose
    .family<List<Associacao>, String>((ref, id) {
      final userId = ref.watch(authUserIdProvider);
      if (userId == null) return Future.value(const <Associacao>[]);
      return ref.watch(imovelRepositoryProvider).associacoes(id);
    });
